#include "Vverilator_tb.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "difftest_dut.h"

#include <algorithm>
#include <cerrno>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

#include <arpa/inet.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>

static constexpr vluint64_t kClkHalfPeriod = 20;
static constexpr vluint64_t kResetReleaseTime = 2000;
static constexpr vluint64_t kUartBitTime = 8960;
static constexpr const char* kWelcome = "MONITOR for Loongarch32 - initialized.";

static vluint64_t main_time = 0;

double sc_time_stamp() {
    return static_cast<double>(main_time);
}

static void queue_uart_byte(std::deque<int>& bits, uint8_t data) {
    bits.push_back(0);
    for (int i = 0; i < 8; ++i) {
        bits.push_back((data >> i) & 1);
    }
    bits.push_back(1);
}

static void queue_uart_word(std::deque<int>& bits, uint32_t data) {
    for (int i = 0; i < 4; ++i) {
        queue_uart_byte(bits, static_cast<uint8_t>(data >> (i * 8)));
    }
}

static bool parse_word_list(const std::string& text, std::vector<uint32_t>& words) {
    size_t begin = 0;
    while (begin < text.size()) {
        size_t end = text.find(',', begin);
        std::string token = text.substr(begin, end - begin);
        size_t first = token.find_first_not_of(" \t");
        size_t last = token.find_last_not_of(" \t");
        if (first == std::string::npos) {
            return false;
        }
        token = token.substr(first, last - first + 1);

        char* parse_end = nullptr;
        uint64_t value = std::strtoull(token.c_str(), &parse_end, 16);
        if (*parse_end != '\0' || value > 0xffffffffULL) {
            return false;
        }
        words.push_back(static_cast<uint32_t>(value));

        if (end == std::string::npos) {
            break;
        }
        begin = end + 1;
    }
    return !words.empty();
}

static bool read_word_file(const std::string& path, std::vector<uint32_t>& words) {
    std::ifstream file(path);
    if (!file) {
        return false;
    }

    std::string token;
    while (file >> token) {
        if (token[0] == '#' || token.compare(0, 2, "//") == 0) {
            std::getline(file, token);
            continue;
        }
        char* parse_end = nullptr;
        uint64_t value = std::strtoull(token.c_str(), &parse_end, 16);
        if (*parse_end != '\0' || value > 0xffffffffULL) {
            return false;
        }
        words.push_back(static_cast<uint32_t>(value));
    }
    return !words.empty();
}

static std::vector<uint8_t> words_to_le_bytes(const std::vector<uint32_t>& words) {
    std::vector<uint8_t> bytes;
    bytes.reserve(words.size() * 4U);
    for (uint32_t word : words) {
        for (int i = 0; i < 4; ++i) {
            bytes.push_back(static_cast<uint8_t>(word >> (i * 8)));
        }
    }
    return bytes;
}

struct ExpectedRegister {
    uint32_t index;
    uint32_t value;
};

static bool parse_register_list(const std::string& text,
                                std::vector<ExpectedRegister>& registers) {
    size_t begin = 0;
    while (begin < text.size()) {
        size_t end = text.find(',', begin);
        std::string token = text.substr(begin, end - begin);
        size_t separator = token.find(':');
        if (separator == std::string::npos) {
            return false;
        }

        std::string reg = token.substr(0, separator);
        std::string value = token.substr(separator + 1);
        size_t reg_first = reg.find_first_not_of(" \t");
        size_t reg_last = reg.find_last_not_of(" \t");
        size_t value_first = value.find_first_not_of(" \t");
        size_t value_last = value.find_last_not_of(" \t");
        if (reg_first == std::string::npos || value_first == std::string::npos) {
            return false;
        }
        reg = reg.substr(reg_first, reg_last - reg_first + 1);
        value = value.substr(value_first, value_last - value_first + 1);
        if (reg[0] == 'r' || reg[0] == 'R') {
            reg.erase(0, 1);
        }

        char* reg_end = nullptr;
        char* value_end = nullptr;
        uint64_t reg_index = std::strtoull(reg.c_str(), &reg_end, 10);
        uint64_t reg_value = std::strtoull(value.c_str(), &value_end, 16);
        if (*reg_end != '\0' || *value_end != '\0' ||
            reg_index < 2 || reg_index > 31 || reg_value > 0xffffffffULL) {
            return false;
        }
        registers.push_back({static_cast<uint32_t>(reg_index),
                             static_cast<uint32_t>(reg_value)});

        if (end == std::string::npos) {
            break;
        }
        begin = end + 1;
    }
    return !registers.empty();
}

static void queue_supervisor_a(std::deque<int>& bits, uint32_t load_addr,
                               const std::vector<uint32_t>& words) {
    queue_uart_byte(bits, 'A');
    queue_uart_word(bits, load_addr);
    queue_uart_word(bits, static_cast<uint32_t>(words.size() * 4U));
    for (uint32_t word : words) {
        queue_uart_word(bits, word);
    }
}

static void queue_supervisor_d(std::deque<int>& bits, uint32_t addr, uint32_t size) {
    queue_uart_byte(bits, 'D');
    queue_uart_word(bits, addr);
    queue_uart_word(bits, size);
}

static void queue_supervisor_g(std::deque<int>& bits, uint32_t entry) {
    queue_uart_byte(bits, 'G');
    queue_uart_word(bits, entry);
}

static void queue_supervisor_r(std::deque<int>& bits) {
    queue_uart_byte(bits, 'R');
}

enum class PendingCommand {
    None,
    LegacyRun,
    LoadAndReadback,
    Run,
    ReadRegisters,
    ReadResult
};

enum class UartCheckPhase {
    Disabled,
    WaitWelcome,
    LoadReadback,
    WaitProgramStart,
    ProgramRunning,
    RegisterReadback,
    ResultReadback,
    Done
};

static bool plusarg_present(int argc, char** argv, const char* name) {
    std::string arg_name = std::string("+") + name;
    for (int i = 1; i < argc; ++i) {
        if (arg_name == argv[i]) {
            return true;
        }
    }
    return false;
}

static uint64_t plusarg_u64(int argc, char** argv, const char* name, uint64_t fallback) {
    std::string prefix = std::string("+") + name + "=";
    for (int i = 1; i < argc; ++i) {
        if (std::strncmp(argv[i], prefix.c_str(), prefix.size()) == 0) {
            return std::strtoull(argv[i] + prefix.size(), nullptr, 0);
        }
    }
    return fallback;
}

static std::string plusarg_string(int argc, char** argv, const char* name) {
    std::string prefix = std::string("+") + name + "=";
    for (int i = 1; i < argc; ++i) {
        if (std::strncmp(argv[i], prefix.c_str(), prefix.size()) == 0) {
            return argv[i] + prefix.size();
        }
    }
    return "";
}

static uint32_t normalize_ext_byte_addr(uint64_t addr) {
    if (addr >= 0x1c400000ULL && addr < 0x1c800000ULL) {
        return static_cast<uint32_t>(addr - 0x1c400000ULL);
    }
    return static_cast<uint32_t>(addr);
}

static uint32_t read_ext_word(Vverilator_tb& top, uint32_t word_addr) {
    top.ext_ram_dump_addr = word_addr;
    top.eval();
    return top.ext_ram_dump_data;
}

static uint8_t read_ext_byte(Vverilator_tb& top, uint32_t byte_addr) {
    uint32_t word = read_ext_word(top, byte_addr >> 2);
    return static_cast<uint8_t>((word >> ((byte_addr & 3U) * 8U)) & 0xffU);
}

static uint32_t read_le_word(const std::vector<uint8_t>& bytes, size_t offset) {
    return static_cast<uint32_t>(bytes[offset]) |
           (static_cast<uint32_t>(bytes[offset + 1]) << 8) |
           (static_cast<uint32_t>(bytes[offset + 2]) << 16) |
           (static_cast<uint32_t>(bytes[offset + 3]) << 24);
}

static bool compare_uart_bytes(const char* label, const std::vector<uint8_t>& actual,
                               const std::vector<uint8_t>& expected) {
    uint32_t mismatches = 0;
    for (size_t i = 0; i < expected.size(); ++i) {
        if (actual[i] != expected[i]) {
            if (mismatches < 8) {
                std::cerr << "[TB] " << label << " mismatch +0x"
                          << std::hex << i
                          << ": expected=0x" << static_cast<unsigned>(expected[i])
                          << " actual=0x" << static_cast<unsigned>(actual[i])
                          << std::dec << "\n";
            }
            ++mismatches;
        }
    }
    if (mismatches != 0) {
        std::cerr << "[TB] " << label << " FAIL: " << mismatches
                  << " mismatches in " << expected.size() << " bytes\n";
        return false;
    }
    std::cout << "[TB] " << label << " PASS: " << expected.size()
              << " bytes match\n";
    return true;
}

static bool compare_uart_registers(const std::vector<uint8_t>& response,
                                   const std::vector<ExpectedRegister>& expected) {
    bool pass = true;
    for (const ExpectedRegister& reg : expected) {
        // R returns uregs[0], followed by r2..r31 in uregs[1]..uregs[30].
        uint32_t actual = read_le_word(response, (reg.index - 1U) * 4U);
        std::cout << "[TB] R r" << reg.index
                  << ": expected=0x" << std::hex << std::setw(8)
                  << std::setfill('0') << reg.value
                  << " actual=0x" << std::setw(8) << actual
                  << std::dec << std::setfill(' ') << "\n";
        if (actual != reg.value) {
            pass = false;
        }
    }
    if (pass) {
        std::cout << "[TB] R register check PASS: " << expected.size()
                  << " registers match\n";
    } else {
        std::cerr << "[TB] R register check FAIL\n";
    }
    return pass;
}

class TcpUartBridge {
public:
    ~TcpUartBridge() {
        close_all();
    }

    bool start(const std::string& bind_address, uint16_t port) {
        listen_fd_ = socket(AF_INET, SOCK_STREAM, 0);
        if (listen_fd_ < 0) {
            failed_ = true;
            std::cerr << "[TB] TCP socket failed: " << std::strerror(errno) << "\n";
            return false;
        }

        int reuse = 1;
        setsockopt(listen_fd_, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

        sockaddr_in address = {};
        address.sin_family = AF_INET;
        address.sin_port = htons(port);
        if (inet_pton(AF_INET, bind_address.c_str(), &address.sin_addr) != 1) {
            failed_ = true;
            std::cerr << "[TB] Invalid +term_bind IPv4 address: "
                      << bind_address << "\n";
            return false;
        }
        if (bind(listen_fd_, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0) {
            failed_ = true;
            std::cerr << "[TB] TCP bind failed: " << std::strerror(errno) << "\n";
            return false;
        }
        if (listen(listen_fd_, 1) < 0) {
            failed_ = true;
            std::cerr << "[TB] TCP listen failed: " << std::strerror(errno) << "\n";
            return false;
        }

        std::cout << "[TB] TCP UART listening on " << bind_address << ":" << port
                  << "\n[TB] Connect with: python3 "
                  << "sdk/software/examples/supervisor/term/term.py -t "
                  << bind_address << ":" << port << "\n" << std::flush;

        do {
            client_fd_ = accept(listen_fd_, nullptr, nullptr);
        } while (client_fd_ < 0 && errno == EINTR);
        if (client_fd_ < 0) {
            failed_ = true;
            std::cerr << "[TB] TCP accept failed: " << std::strerror(errno) << "\n";
            return false;
        }
        std::cout << "[TB] term.py connected\n" << std::flush;
        return true;
    }

    bool receive(std::vector<uint8_t>& bytes, bool wait) {
        pollfd descriptor = {client_fd_, POLLIN, 0};
        int result;
        do {
            result = poll(&descriptor, 1, wait ? -1 : 0);
        } while (result < 0 && errno == EINTR);
        if (result < 0) {
            failed_ = true;
            std::cerr << "[TB] TCP poll failed: " << std::strerror(errno) << "\n";
            return false;
        }
        if (result == 0) {
            return true;
        }
        if ((descriptor.revents & POLLIN) != 0) {
            uint8_t buffer[4096];
            ssize_t received;
            do {
                received = recv(client_fd_, buffer, sizeof(buffer), 0);
            } while (received < 0 && errno == EINTR);
            if (received > 0) {
                bytes.insert(bytes.end(), buffer, buffer + received);
                return true;
            }
            if (received == 0) {
                std::cout << "[TB] term.py disconnected\n";
                return false;
            }
            std::cerr << "[TB] TCP receive failed: " << std::strerror(errno) << "\n";
            failed_ = true;
            return false;
        }
        if ((descriptor.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) {
            std::cout << "[TB] term.py disconnected\n";
            return false;
        }
        return true;
    }

    bool send_byte(uint8_t byte) {
        const uint8_t* data = &byte;
        size_t remaining = 1;
        while (remaining != 0) {
            ssize_t sent = send(client_fd_, data, remaining, MSG_NOSIGNAL);
            if (sent > 0) {
                data += sent;
                remaining -= static_cast<size_t>(sent);
            } else if (sent < 0 && errno == EINTR) {
                continue;
            } else {
                std::cerr << "[TB] TCP send failed: " << std::strerror(errno) << "\n";
                failed_ = true;
                return false;
            }
        }
        return true;
    }

    bool failed() const {
        return failed_;
    }

private:
    void close_all() {
        if (client_fd_ >= 0) {
            close(client_fd_);
            client_fd_ = -1;
        }
        if (listen_fd_ >= 0) {
            close(listen_fd_);
            listen_fd_ = -1;
        }
    }

    int listen_fd_ = -1;
    int client_fd_ = -1;
    bool failed_ = false;
};

class TermProtocolTracker {
public:
    void consume_input(const std::vector<uint8_t>& bytes) {
        for (uint8_t byte : bytes) {
            needs_settle_ = true;
            if (packet_.empty()) {
                operation_ = byte;
                switch (operation_) {
                case 'R': packet_size_ = 1; break;
                case 'G': packet_size_ = 5; break;
                case 'A':
                case 'D': packet_size_ = 9; break;
                default: packet_size_ = 1; break;
                }
            }
            packet_.push_back(byte);

            if (operation_ == 'A' && packet_.size() == 9U) {
                packet_size_ = 9U + read_le_word(packet_, 5);
            }
            if (packet_.size() == packet_size_) {
                complete_packet();
            }
        }
    }

    void uart_input_drained(vluint64_t now) {
        if (needs_settle_ && !fixed_response_ && !program_response_) {
            settle_until_ = now + 20 * kUartBitTime;
            needs_settle_ = false;
        }
    }

    void consume_output(uint8_t byte, vluint64_t now) {
        if (booting_) {
            if (byte == static_cast<uint8_t>(kWelcome[welcome_match_])) {
                ++welcome_match_;
                if (kWelcome[welcome_match_] == '\0') {
                    booting_ = false;
                    settle_until_ = now + 20 * kUartBitTime;
                }
            } else {
                welcome_match_ =
                    (byte == static_cast<uint8_t>(kWelcome[0])) ? 1 : 0;
            }
            return;
        }

        if (fixed_response_) {
            if (response_remaining_ != 0) {
                --response_remaining_;
            }
            if (response_remaining_ == 0) {
                fixed_response_ = false;
                settle_until_ = now + 20 * kUartBitTime;
            }
        } else if (program_response_ && (byte == 0x07 || byte == 0x80)) {
            program_response_ = false;
            settle_until_ = now + 20 * kUartBitTime;
        }
    }

    bool should_wait(vluint64_t now, bool uart_active,
                     const std::deque<int>& uart_bits) const {
        return !booting_ && !fixed_response_ && !program_response_ &&
               !needs_settle_ && !uart_active && uart_bits.empty() &&
               now >= settle_until_;
    }

private:
    void complete_packet() {
        switch (operation_) {
        case 'R':
            fixed_response_ = true;
            response_remaining_ = 124;
            needs_settle_ = false;
            break;
        case 'D':
            response_remaining_ = read_le_word(packet_, 5);
            fixed_response_ = response_remaining_ != 0;
            needs_settle_ = !fixed_response_;
            break;
        case 'G':
            program_response_ = true;
            needs_settle_ = false;
            break;
        case 'A':
        default:
            break;
        }
        packet_.clear();
        packet_size_ = 0;
        operation_ = 0;
    }

    bool booting_ = true;
    bool fixed_response_ = false;
    bool program_response_ = false;
    bool needs_settle_ = false;
    uint64_t response_remaining_ = 0;
    vluint64_t settle_until_ = 0;
    size_t welcome_match_ = 0;
    uint8_t operation_ = 0;
    size_t packet_size_ = 0;
    std::vector<uint8_t> packet_;
};

static void dump_ext_ram(Vverilator_tb& top, uint32_t byte_addr, uint32_t size) {
    std::cout << std::hex << std::setfill('0');
    std::cout << "\n[TB] Dump ExtRAM byte offset 0x" << std::setw(5) << byte_addr
              << ", size 0x" << size << " (" << std::dec << size << " bytes)\n";
    std::cout << std::hex << std::setfill('0');

    uint32_t end = byte_addr + size;
    for (uint32_t line = byte_addr & ~0xfU; line < end; line += 16) {
        std::cout << std::setw(8) << line << ":";
        for (uint32_t i = 0; i < 16; ++i) {
            uint32_t cur = line + i;
            if (cur >= byte_addr && cur < end) {
                std::cout << " " << std::setw(2)
                          << static_cast<unsigned>(read_ext_byte(top, cur));
            } else {
                std::cout << "   ";
            }
        }
        std::cout << "\n";
    }
    std::cout << std::dec << std::setfill(' ');
}

static bool compare_ext_ram(Vverilator_tb& top, uint32_t byte_addr, const std::string& path,
                            uint32_t max_size, uint32_t mismatch_print_limit) {
    std::ifstream file(path, std::ios::binary);
    if (!file) {
        std::cerr << "[TB] Failed to open compare file: " << path << "\n";
        return false;
    }

    std::vector<uint8_t> expected((std::istreambuf_iterator<char>(file)),
                                  std::istreambuf_iterator<char>());
    if (max_size != 0 && expected.size() > max_size) {
        expected.resize(max_size);
    }

    uint32_t mismatch_count = 0;
    uint32_t first_mismatch = 0;
    uint8_t first_expected = 0;
    uint8_t first_actual = 0;
    std::vector<uint32_t> sample_offsets;
    std::vector<uint8_t> sample_expected;
    std::vector<uint8_t> sample_actual;
    for (uint32_t i = 0; i < expected.size(); ++i) {
        uint8_t actual = read_ext_byte(top, byte_addr + i);
        if (actual != expected[i]) {
            if (mismatch_count == 0) {
                first_mismatch = i;
                first_expected = expected[i];
                first_actual = actual;
            }
            if (sample_offsets.size() < mismatch_print_limit) {
                sample_offsets.push_back(i);
                sample_expected.push_back(expected[i]);
                sample_actual.push_back(actual);
            }
            ++mismatch_count;
        }
    }

    std::cout << std::hex << std::setfill('0');
    if (mismatch_count == 0) {
        std::cout << "[TB] Compare PASS: ExtRAM byte offset 0x" << byte_addr
                  << " matches " << std::dec << expected.size() << " bytes from "
                  << path << "\n";
    } else {
        std::cout << "[TB] Compare FAIL: " << std::dec << mismatch_count
                  << " mismatches in " << expected.size() << " bytes; first at +0x"
                  << std::hex << first_mismatch << " expected=0x"
                  << std::setw(2) << static_cast<unsigned>(first_expected)
                  << " actual=0x" << std::setw(2)
                  << static_cast<unsigned>(first_actual) << "\n";
        for (uint32_t i = 0; i < sample_offsets.size(); ++i) {
            std::cout << "[TB] Mismatch[" << std::dec << i << "]: +0x"
                      << std::hex << sample_offsets[i]
                      << " expected=0x" << std::setw(2)
                      << static_cast<unsigned>(sample_expected[i])
                      << " actual=0x" << std::setw(2)
                      << static_cast<unsigned>(sample_actual[i]) << "\n";
        }
    }
    std::cout << std::dec << std::setfill(' ');
    return mismatch_count == 0;
}

struct CrnRef {
    std::vector<uint32_t> pad;
    uint32_t a = 0xdeadbeefU;
    uint32_t b = 0xfaceb00cU;
    uint32_t iter = 0;

    uint32_t addr1 = 0;
    uint32_t pad1 = 0;
    uint32_t t = 0;
    uint32_t store1 = 0;
    uint32_t addr2 = 0;
    uint32_t pad2 = 0;
    uint32_t product = 0;
    uint32_t a_before_xor = 0;
    uint32_t a_after = 0;

    explicit CrnRef(bool enabled) {
        if (enabled) {
            pad.resize(0x80000);
            for (uint32_t i = 0; i < pad.size(); ++i) {
                pad[i] = i;
            }
            compute();
        }
    }

    void compute() {
        addr1 = a & 0x7ffffU;
        pad1 = pad[addr1];
        t = (a >> 1) ^ (pad1 << 1);
        store1 = t ^ b;
        addr2 = t & 0x7ffffU;
        pad2 = (addr2 == addr1) ? store1 : pad[addr2];
        product = static_cast<uint32_t>(static_cast<uint64_t>(t) * pad2);
        a_before_xor = a + product;
        a_after = a_before_xor ^ pad2;
    }

    bool expected(uint32_t pc, uint32_t& value) const {
        switch (pc) {
        case 0x1c002130U: value = addr1; return true;
        case 0x1c002134U: value = addr1 << 2; return true;
        case 0x1c002138U: value = 0x1c400000U + (addr1 << 2); return true;
        case 0x1c00213cU: value = pad1; return true;
        case 0x1c002140U: value = a >> 1; return true;
        case 0x1c002144U: value = pad1 << 1; return true;
        case 0x1c002148U: value = t; return true;
        case 0x1c00214cU: value = addr2; return true;
        case 0x1c002150U: value = store1; return true;
        case 0x1c002154U: value = addr2 << 2; return true;
        case 0x1c00215cU: value = 0x1c400000U + (addr2 << 2); return true;
        case 0x1c002160U: value = pad2; return true;
        case 0x1c002164U: value = t; return true;
        case 0x1c002168U: value = product; return true;
        case 0x1c00216cU: value = iter + 1; return true;
        case 0x1c002170U: value = a_before_xor; return true;
        case 0x1c002178U: value = a_after; return true;
        default: return false;
        }
    }

    void commit() {
        pad[addr1] = store1;
        pad[addr2] = a_before_xor;
        b = t;
        a = a_after;
        ++iter;
        compute();
    }
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vverilator_tb top;
    top.clk = 0;
    top.reset = 1;
    top.uart_rx = 1;

    bool supervisor_g_sent = false;
    bool supervisor_started = false;
    bool send_scheduled = false;
    bool uart_active = false;
    bool ext_log_all = plusarg_present(argc, argv, "log_ext_ram_all");
    bool ext_log_write = plusarg_present(argc, argv, "log_ext_ram_write");
    std::string ext_log_addr_arg = plusarg_string(argc, argv, "log_ext_ram_addr");
    bool ext_log_range_enable = !ext_log_addr_arg.empty();
    bool ext_log_enable = (ext_log_all || ext_log_write || ext_log_range_enable) &&
                          !plusarg_present(argc, argv, "no_ext_ram_write_log");
    bool ext_log_truncated = false;
    bool trace_boot = plusarg_present(argc, argv, "trace_boot");
    bool check_crn = plusarg_present(argc, argv, "check_crn");
    bool trace_crn_last = plusarg_present(argc, argv, "trace_crn_last");
    std::string trace_pc_range_arg = plusarg_string(argc, argv, "trace_pc_range");
    bool trace_pc_range_en = !trace_pc_range_arg.empty();
    uint32_t trace_pc_start = 0;
    uint32_t trace_pc_end = 0;
    if (trace_pc_range_en) {
        size_t sep = trace_pc_range_arg.find(':');
        if (sep == std::string::npos) {
            trace_pc_start = static_cast<uint32_t>(std::strtoull(trace_pc_range_arg.c_str(), nullptr, 0));
            trace_pc_end = trace_pc_start;
        } else {
            trace_pc_start = static_cast<uint32_t>(
                std::strtoull(trace_pc_range_arg.substr(0, sep).c_str(), nullptr, 0));
            trace_pc_end = static_cast<uint32_t>(
                std::strtoull(trace_pc_range_arg.substr(sep + 1).c_str(), nullptr, 0));
        }
    }
    uint64_t trace_crn_last_count = 0;
    uint64_t trace_crn_limit = plusarg_u64(argc, argv, "trace_crn_limit", 0);
    uint64_t trace_crn_count = 0;
    bool stop_after_trace_crn = plusarg_present(argc, argv, "stop_after_trace_crn");
    int welcome_match = 0;
    uint64_t ext_log_count = 0;
    uint64_t ext_log_limit = plusarg_u64(argc, argv, "ext_ram_write_log_limit", 2048);
    uint32_t ext_log_start = 0;
    if (ext_log_range_enable) {
        ext_log_start = normalize_ext_byte_addr(std::strtoull(ext_log_addr_arg.c_str(), nullptr, 0));
    }
    uint32_t ext_log_size = static_cast<uint32_t>(plusarg_u64(argc, argv, "log_ext_ram_size", 4));
    if (ext_log_size == 0) {
        ext_log_size = 4;
    }
    uint64_t ext_log_end = static_cast<uint64_t>(ext_log_start) + ext_log_size;
    uint64_t max_time = plusarg_u64(argc, argv, "max_time", 200000000000ULL);
    std::string term_port_arg = plusarg_string(argc, argv, "term_port");
    bool term_mode = !term_port_arg.empty();
    uint16_t term_port = 0;
    if (term_mode) {
        char* parse_end = nullptr;
        uint64_t parsed_port = std::strtoull(term_port_arg.c_str(), &parse_end, 0);
        if (*parse_end != '\0' || parsed_port == 0 || parsed_port > 65535) {
            std::cerr << "[TB] Invalid +term_port, expected 1..65535\n";
            return 2;
        }
        term_port = static_cast<uint16_t>(parsed_port);
    }
    std::string term_bind = plusarg_string(argc, argv, "term_bind");
    if (term_bind.empty()) {
        term_bind = "127.0.0.1";
    }
    std::string wave_file = plusarg_string(argc, argv, "wave_file");
    bool wave_enable = plusarg_present(argc, argv, "wave") || !wave_file.empty();
    if (plusarg_present(argc, argv, "no_wave")) {
        wave_enable = false;
    }
    if (wave_file.empty()) {
        wave_file = "sim/verilator/wave.fst";
    }
    bool supervisor_uart_check = plusarg_present(argc, argv, "supervisor_uart_check");
    std::string supervisor_a_words_arg = plusarg_string(argc, argv, "supervisor_a_words");
    std::string supervisor_a_file = plusarg_string(argc, argv, "supervisor_a_file");
    std::vector<uint32_t> supervisor_a_words;
    if (!supervisor_a_words_arg.empty() && !supervisor_a_file.empty()) {
        std::cerr << "[TB] Use only one of +supervisor_a_words or +supervisor_a_file\n";
        return 2;
    }
    if (!supervisor_a_words_arg.empty() &&
        !parse_word_list(supervisor_a_words_arg, supervisor_a_words)) {
        std::cerr << "[TB] Invalid +supervisor_a_words list\n";
        return 2;
    }
    if (!supervisor_a_file.empty() &&
        !read_word_file(supervisor_a_file, supervisor_a_words)) {
        std::cerr << "[TB] Invalid or empty +supervisor_a_file: "
                  << supervisor_a_file << "\n";
        return 2;
    }
    uint32_t supervisor_a_addr = static_cast<uint32_t>(
        plusarg_u64(argc, argv, "supervisor_a_addr", 0x1c300000));
    std::string supervisor_entry_arg = plusarg_string(argc, argv, "supervisor_entry");
    bool supervisor_entry_provided = !supervisor_entry_arg.empty();
    uint32_t supervisor_entry = supervisor_entry_provided ?
        static_cast<uint32_t>(plusarg_u64(argc, argv, "supervisor_entry", 0)) :
        supervisor_a_addr;
    std::string supervisor_expected_regs_arg =
        plusarg_string(argc, argv, "supervisor_expected_regs");
    std::vector<ExpectedRegister> supervisor_expected_regs;
    if (!supervisor_expected_regs_arg.empty() &&
        !parse_register_list(supervisor_expected_regs_arg, supervisor_expected_regs)) {
        std::cerr << "[TB] Invalid +supervisor_expected_regs list\n";
        return 2;
    }
    uint32_t supervisor_result_addr = static_cast<uint32_t>(
        plusarg_u64(argc, argv, "supervisor_result_addr", 0x1c400000));
    std::string supervisor_result_words_arg =
        plusarg_string(argc, argv, "supervisor_result_words");
    std::vector<uint32_t> supervisor_result_words;
    if (!supervisor_result_words_arg.empty() &&
        !parse_word_list(supervisor_result_words_arg, supervisor_result_words)) {
        std::cerr << "[TB] Invalid +supervisor_result_words list\n";
        return 2;
    }
    if (supervisor_uart_check &&
        (supervisor_a_words.empty() || supervisor_expected_regs.empty() ||
         supervisor_result_words.empty())) {
        std::cerr << "[TB] +supervisor_uart_check requires program words/file, "
                  << "+supervisor_expected_regs, and +supervisor_result_words\n";
        return 2;
    }
    if (term_mode && supervisor_uart_check) {
        std::cerr << "[TB] +term_port and +supervisor_uart_check are separate modes\n";
        return 2;
    }
    if (!term_mode && !supervisor_uart_check &&
        !supervisor_entry_provided && supervisor_a_words.empty()) {
        std::cerr << "[TB] Automatic mode requires +supervisor_entry or an A program\n";
        return 2;
    }
    std::vector<uint8_t> supervisor_program_bytes =
        words_to_le_bytes(supervisor_a_words);
    std::vector<uint8_t> supervisor_result_bytes =
        words_to_le_bytes(supervisor_result_words);
    uint32_t dump_ext_addr = normalize_ext_byte_addr(plusarg_u64(argc, argv, "dump_ext_addr", 0x20000));
    uint32_t dump_ext_size = static_cast<uint32_t>(plusarg_u64(argc, argv, "dump_ext_size", 200));
    std::string compare_ext_file = plusarg_string(argc, argv, "compare_ext_file");
    uint32_t compare_ext_addr = normalize_ext_byte_addr(
        plusarg_u64(argc, argv, "compare_ext_addr", dump_ext_addr));
    uint32_t compare_ext_size = static_cast<uint32_t>(
        plusarg_u64(argc, argv, "compare_ext_size", 0));
    uint32_t compare_mismatch_limit = static_cast<uint32_t>(
        plusarg_u64(argc, argv, "compare_mismatch_limit", 0));
    std::string trace_data_addr_arg = plusarg_string(argc, argv, "trace_data_addr");
    bool trace_data_addr_en = !trace_data_addr_arg.empty();
    uint32_t trace_data_phys = 0;
    bool trace_target_lookup_pending = false;
    if (trace_data_addr_en) {
        uint64_t raw_trace_addr = std::strtoull(trace_data_addr_arg.c_str(), nullptr, 0);
        trace_data_phys = (raw_trace_addr < 0x00400000ULL) ?
                          static_cast<uint32_t>(0x1c400000ULL + raw_trace_addr) :
                          static_cast<uint32_t>(raw_trace_addr);
    }
    bool compare_pass = true;
    bool uart_check_pass = true;
    bool uart_check_done = false;
    uint64_t heartbeat_cycles = plusarg_u64(argc, argv, "heartbeat_cycles", 0);
    uint64_t clk_cycles = 0;
    uint32_t last_trace_pc = 0xffffffffU;
    vluint64_t next_clk = kClkHalfPeriod;
    vluint64_t send_time = 0;
    vluint64_t uart_next_time = 0;
    std::deque<int> uart_bits;
    std::vector<uint8_t> uart_response;
    PendingCommand pending_command = PendingCommand::None;
    UartCheckPhase uart_check_phase = supervisor_uart_check ?
        UartCheckPhase::WaitWelcome : UartCheckPhase::Disabled;
    CrnRef crn_ref(check_crn);
    TcpUartBridge term_bridge;
    TermProtocolTracker term_tracker;
    bool term_disconnected = false;
    VerilatedFstC wave;

    if (wave_enable) {
        Verilated::traceEverOn(true);
        top.trace(&wave, 99);
        wave.open(wave_file.c_str());
        std::cout << "[TB] FST waveform: " << wave_file << "\n";
    }
    top.eval();
    if (wave_enable) {
        wave.dump(main_time);
    }
    if (term_mode && !term_bridge.start(term_bind, term_port)) {
        if (wave_enable) {
            wave.close();
        }
        return 2;
    }

    if (ext_log_enable) {
        if (ext_log_all || !ext_log_range_enable) {
            std::cout << "[TB] ExtRAM write log enabled: all writes"
                      << ", limit=" << ext_log_limit << "\n";
        } else {
            std::cout << "[TB] ExtRAM write log enabled: byte_offset=0x"
                      << std::hex << ext_log_start
                      << " size=0x" << ext_log_size
                      << std::dec << ", limit=" << ext_log_limit << "\n";
        }
    }

    bool difftest_on = false;
    std::string diff_so = plusarg_string(argc, argv, "diff_so");
    std::string diff_img = plusarg_string(argc, argv, "diff_img");
    if (!diff_so.empty() && !diff_img.empty()) {
        std::ifstream img_file(diff_img, std::ios::binary | std::ios::ate);
        if (img_file) {
            size_t img_size = img_file.tellg();
            img_file.seekg(0, std::ios::beg);
            std::vector<uint8_t> img_data(img_size);
            img_file.read(reinterpret_cast<char*>(img_data.data()), img_size);
            difftest_set_program(img_data.data(), img_size);
            difftest_on = difftest_init(diff_so.c_str(), nullptr);
            if (difftest_on) {
                std::cout << "[DIFFTEST] Enabled with " << diff_so
                          << ", image " << diff_img
                          << " (" << img_size << " bytes)\n";
                std::string base_mif = plusarg_string(argc, argv, "base_ram_mif");
                if (!base_mif.empty() && base_mif != "none") {
                    difftest_load_mif(base_mif.c_str(), 0x1c000000);
                }
                std::string ext_mif = plusarg_string(argc, argv, "ext_ram_mif");
                if (!ext_mif.empty() && ext_mif != "none") {
                    difftest_load_mif(ext_mif.c_str(), 0x1c400000);
                }
            }
        } else {
            std::cerr << "[DIFFTEST] Cannot open image: " << diff_img << "\n";
        }
    }

    while (!Verilated::gotFinish() && (term_mode || main_time < max_time)) {
        top.eval();

        if (term_mode &&
            term_tracker.should_wait(main_time, uart_active, uart_bits)) {
            if (wave_enable) {
                wave.flush();
            }
            std::vector<uint8_t> term_input;
            if (!term_bridge.receive(term_input, true)) {
                term_disconnected = true;
                break;
            }
            term_tracker.consume_input(term_input);
            for (uint8_t byte : term_input) {
                queue_uart_byte(uart_bits, byte);
            }
            if (!uart_bits.empty()) {
                uart_active = true;
                uart_next_time = main_time;
            }
        }

        vluint64_t next_time = next_clk;
        if (main_time < kResetReleaseTime) {
            next_time = std::min(next_time, kResetReleaseTime);
        }
        if (send_scheduled && !uart_active) {
            next_time = std::min(next_time, send_time);
        }
        if (uart_active) {
            next_time = std::min(next_time, uart_next_time);
        }
        if (next_time <= main_time) {
            next_time = main_time + 1;
        }

        Verilated::timeInc(next_time - main_time);
        main_time = next_time;

        bool clk_posedge = false;
        if (main_time == next_clk) {
            top.clk = !top.clk;
            clk_posedge = top.clk;
            next_clk += kClkHalfPeriod;
        }
        if (main_time >= kResetReleaseTime) {
            top.reset = 0;
        }
        if (send_scheduled && !uart_active && main_time >= send_time) {
            send_scheduled = false;
            switch (pending_command) {
            case PendingCommand::LegacyRun:
                if (!supervisor_a_words.empty()) {
                    queue_supervisor_a(uart_bits, supervisor_a_addr,
                                       supervisor_a_words);
                    std::cout << "\n[TB] Send supervisor command: A 0x"
                              << std::hex << supervisor_a_addr << ", 0x"
                              << supervisor_program_bytes.size() << " bytes\n";
                }
                queue_supervisor_g(uart_bits, supervisor_entry);
                supervisor_g_sent = true;
                std::cout << "[TB] Send supervisor command: G 0x"
                          << std::hex << supervisor_entry << std::dec << "\n"
                          << std::flush;
                break;
            case PendingCommand::LoadAndReadback:
                queue_supervisor_a(uart_bits, supervisor_a_addr,
                                   supervisor_a_words);
                queue_supervisor_d(uart_bits, supervisor_a_addr,
                                   static_cast<uint32_t>(supervisor_program_bytes.size()));
                uart_response.clear();
                uart_check_phase = UartCheckPhase::LoadReadback;
                std::cout << "\n[TB] Send supervisor command: A 0x"
                          << std::hex << supervisor_a_addr << ", 0x"
                          << supervisor_program_bytes.size() << " bytes\n"
                          << "[TB] Send supervisor command: D 0x"
                          << supervisor_a_addr << ", 0x"
                          << supervisor_program_bytes.size() << " bytes\n"
                          << std::dec << std::flush;
                break;
            case PendingCommand::Run:
                queue_supervisor_g(uart_bits, supervisor_entry);
                supervisor_g_sent = true;
                uart_check_phase = UartCheckPhase::WaitProgramStart;
                std::cout << "[TB] Send supervisor command: G 0x"
                          << std::hex << supervisor_entry << std::dec << "\n"
                          << std::flush;
                break;
            case PendingCommand::ReadRegisters:
                queue_supervisor_r(uart_bits);
                uart_response.clear();
                uart_check_phase = UartCheckPhase::RegisterReadback;
                std::cout << "[TB] Send supervisor command: R\n" << std::flush;
                break;
            case PendingCommand::ReadResult:
                queue_supervisor_d(uart_bits, supervisor_result_addr,
                                   static_cast<uint32_t>(supervisor_result_bytes.size()));
                uart_response.clear();
                uart_check_phase = UartCheckPhase::ResultReadback;
                std::cout << "[TB] Send supervisor command: D 0x"
                          << std::hex << supervisor_result_addr << ", 0x"
                          << supervisor_result_bytes.size() << " bytes\n"
                          << std::dec << std::flush;
                break;
            case PendingCommand::None:
                break;
            }
            pending_command = PendingCommand::None;
            uart_active = !uart_bits.empty();
            if (uart_active) {
                uart_next_time = main_time;
            }
        }
        if (uart_active && main_time >= uart_next_time) {
            if (!uart_bits.empty()) {
                top.uart_rx = uart_bits.front();
                uart_bits.pop_front();
                uart_next_time = main_time + kUartBitTime;
            } else {
                top.uart_rx = 1;
                uart_active = false;
                if (term_mode) {
                    term_tracker.uart_input_drained(main_time);
                }
            }
        }

        top.eval();
        if (wave_enable) {
            wave.dump(main_time);
        }

        if (clk_posedge) {
            ++clk_cycles;
            if (difftest_on) {
                difftest_step();
            }
            if (heartbeat_cycles != 0 && (clk_cycles % heartbeat_cycles) == 0) {
                std::cout << "[TB] Heartbeat: cycles=" << clk_cycles
                          << " t=" << main_time
                          << " pc=0x" << std::hex << top.debug_wb_pc
                          << std::dec << "\n" << std::flush;
            }
            if (trace_data_addr_en) {
                uint32_t trace_line = trace_data_phys & ~0xfU;
                uint32_t trace_word = trace_data_phys & ~0x3U;
                uint32_t trace_tag = trace_data_phys >> 12;
                uint32_t trace_index = (trace_data_phys >> 4) & 0xffU;
                uint32_t trace_offset_word = trace_data_phys & 0xcU;
                uint32_t req_phys = (static_cast<uint32_t>(top.data_tag) << 12) |
                                    (static_cast<uint32_t>(top.data_index) << 4) |
                                    static_cast<uint32_t>(top.data_offset);
                if (top.data_valid && top.data_op && top.data_addr_ok &&
                    ((req_phys & ~0x3U) == trace_word)) {
                    std::cout << "[DSTORE_ACCEPT] t=" << main_time
                              << " phys=0x" << std::hex << req_phys
                              << " vaddr=0x" << top.data_vaddr
                              << " wstrb=0x" << static_cast<unsigned>(top.data_wstrb)
                              << " wdata=0x" << top.data_wdata
                              << " wb_pc=0x" << top.debug_wb_pc
                              << std::dec << "\n";
                }
                if (trace_target_lookup_pending) {
                    if (top.dcache_write_full &&
                        static_cast<uint32_t>(top.dcache_write_index) == trace_index &&
                        (static_cast<uint32_t>(top.dcache_write_offset) & 0xcU) == trace_offset_word) {
                        std::cout << "[DSTORE_COMMIT] t=" << main_time
                                  << " index=0x" << std::hex << static_cast<unsigned>(top.dcache_write_index)
                                  << " off=0x" << static_cast<unsigned>(top.dcache_write_offset)
                                  << " way=0x" << static_cast<unsigned>(top.dcache_write_way)
                                  << " wdata=0x" << top.dcache_write_wdata
                                  << " pc=0x" << top.debug_wb_pc
                                  << std::dec << "\n";
                    }
                    trace_target_lookup_pending = false;
                }
                if ((top.dcache_main_state & 0x02U) && top.dcache_req_op &&
                    static_cast<uint32_t>(top.data_tag) == trace_tag &&
                    static_cast<uint32_t>(top.dcache_req_index) == trace_index &&
                    (static_cast<uint32_t>(top.dcache_req_offset) & 0xcU) == trace_offset_word) {
                    std::cout << "[DLOOKUP_TARGET] t=" << main_time
                              << " tag_in=0x" << std::hex << top.data_tag
                              << " index=0x" << static_cast<unsigned>(top.dcache_req_index)
                              << " off=0x" << static_cast<unsigned>(top.dcache_req_offset)
                              << " hit=" << std::dec << static_cast<unsigned>(top.dcache_cache_hit)
                              << " way=0x" << std::hex << static_cast<unsigned>(top.dcache_way_hit)
                              << " wdata=0x" << top.dcache_req_wdata
                              << " pc=0x" << top.debug_wb_pc
                              << std::dec << "\n";
                    trace_target_lookup_pending = true;
                }
                if ((top.dcache_main_state & 0x02U) && top.dcache_req_dcacop &&
                    static_cast<uint32_t>(top.dcache_req_index) == trace_index) {
                    std::cout << "[DCACOP_TARGET_SET] t=" << main_time
                              << " mode=" << std::dec << static_cast<unsigned>(top.dcache_req_cacop_mode)
                              << " off=0x" << std::hex << static_cast<unsigned>(top.dcache_req_offset)
                              << " tag_in=0x" << top.data_tag
                              << " way_d=0x" << static_cast<unsigned>(top.dcache_way_d)
                              << " repl_way=0x" << static_cast<unsigned>(top.dcache_replace_way)
                              << " repl_d=" << std::dec << static_cast<unsigned>(top.dcache_replace_d)
                              << " repl_v=" << static_cast<unsigned>(top.dcache_replace_v)
                              << " repl_tag=0x" << std::hex << top.dcache_replace_tag
                              << " pc=0x" << top.debug_wb_pc
                              << std::dec << "\n";
                }
                if (top.data_wr_req && ((top.data_wr_addr & ~0xfU) == trace_line)) {
                    uint32_t lane = (trace_data_phys >> 2) & 3U;
                    uint32_t line_word = top.data_wr_data[lane];
                    std::cout << "[DWRITEBACK_REQ] t=" << main_time
                              << " line=0x" << std::hex << top.data_wr_addr
                              << " lane=" << std::dec << lane
                              << " word=0x" << std::hex << line_word
                              << " w0=0x" << top.data_wr_data[0]
                              << " w1=0x" << top.data_wr_data[1]
                              << " w2=0x" << top.data_wr_data[2]
                              << " w3=0x" << top.data_wr_data[3]
                              << std::dec << "\n";
                }
                if (top.ext_ram_write_fire) {
                    uint32_t ext_phys = 0x1c400000U +
                                        (static_cast<uint32_t>(top.ext_ram_write_addr) << 2);
                    if ((ext_phys & ~0x3U) == trace_word) {
                        std::cout << "[EXT_TARGET_W] t=" << main_time
                                  << " phys=0x" << std::hex << ext_phys
                                  << " be=0x" << (~top.ext_ram_write_be_n & 0xf)
                                  << " data=0x" << top.ext_ram_write_data
                                  << std::dec << "\n";
                    }
                }
            }
        }

        if (clk_posedge && trace_boot) {
            if (top.debug_wb_pc != last_trace_pc) {
                std::cout << "[PC] t=" << main_time
                          << " pc=" << std::hex << top.debug_wb_pc
                          << " inst=" << top.debug_wb_inst
                          << std::dec << "\n";
                last_trace_pc = top.debug_wb_pc;
            }
            if (top.cpu_ar_fire) {
                std::cout << "[AR] t=" << main_time
                          << " addr=" << std::hex << top.cpu_ar_addr
                          << " vaddr=" << top.data_vaddr
                          << " d_rd=" << top.data_rd_addr
                          << " dmw1=" << top.csr_dmw1
                          << " da=" << std::dec << static_cast<int>(top.csr_da)
                          << " pg=" << static_cast<int>(top.csr_pg)
                          << " uncache=" << static_cast<int>(top.data_uncache_en)
                          << std::dec << "\n";
            }
            if (top.cpu_aw_fire) {
                std::cout << "[AW] t=" << main_time
                          << " addr=" << std::hex << top.cpu_aw_addr
                          << std::dec << "\n";
            }
        }
        if (clk_posedge && trace_pc_range_en) {
            uint32_t pc = top.debug_wb_pc;
            if (pc >= trace_pc_start && pc <= trace_pc_end && pc != last_trace_pc) {
                std::cout << "[PC_RANGE] t=" << main_time
                          << " pc=0x" << std::hex << pc
                          << " inst=0x" << top.debug_wb_inst;
                if (top.debug_wb_rf_wen != 0) {
                    std::cout << " w" << std::dec
                              << static_cast<unsigned>(top.debug_wb_rf_wnum)
                              << "=0x" << std::hex << top.debug_wb_rf_wdata;
                }
                std::cout << std::dec << "\n";
                last_trace_pc = pc;
            }
        }

        if (clk_posedge && check_crn && top.debug_wb_rf_wen != 0) {
            uint32_t expected_value = 0;
            uint32_t pc = top.debug_wb_pc;
            if (crn_ref.expected(pc, expected_value)) {
                uint32_t actual_value = top.debug_wb_rf_wdata;
                if (actual_value != expected_value) {
                    std::cout << "[CRN_MISMATCH] iter=" << std::dec << crn_ref.iter
                              << " pc=0x" << std::hex << pc
                              << " expected=0x" << expected_value
                              << " actual=0x" << actual_value
                              << " a=0x" << crn_ref.a
                              << " b=0x" << crn_ref.b
                              << " addr1=0x" << crn_ref.addr1
                              << " addr2=0x" << crn_ref.addr2
                              << " pad1=0x" << crn_ref.pad1
                              << " pad2=0x" << crn_ref.pad2
                              << std::dec << "\n";
                    compare_pass = false;
                    break;
                }
                if (pc == 0x1c002178U) {
                    crn_ref.commit();
                }
            }
        }

        if (clk_posedge && trace_crn_last && top.debug_wb_rf_wen != 0 &&
            top.debug_wb_pc == 0x1c00216cU &&
            top.debug_wb_rf_wnum == 13U &&
            top.debug_wb_rf_wdata == 0x00100000U) {
            trace_crn_last_count = 1;
        }

        if (clk_posedge && trace_crn_last_count != 0 &&
            top.debug_wb_rf_wen != 0 &&
            top.debug_wb_pc >= 0x1c002130U && top.debug_wb_pc <= 0x1c00217cU) {
            std::cout << "[CRN_LAST] t=" << main_time
                      << " pc=0x" << std::hex << top.debug_wb_pc
                      << " inst=0x" << top.debug_wb_inst
                      << " w" << std::dec << static_cast<unsigned>(top.debug_wb_rf_wnum)
                      << "=0x" << std::hex << top.debug_wb_rf_wdata
                      << std::dec << "\n";
            ++trace_crn_last_count;
            if (trace_crn_last_count > 32) {
                trace_crn_last_count = 0;
            }
        }

        if (clk_posedge && trace_crn_limit != 0 && top.debug_wb_rf_wen != 0 &&
            top.debug_wb_pc >= 0x1c002130U && top.debug_wb_pc <= 0x1c00217cU &&
            trace_crn_count < trace_crn_limit) {
            std::cout << "[CRN] t=" << main_time
                      << " pc=0x" << std::hex << top.debug_wb_pc
                      << " inst=0x" << top.debug_wb_inst
                      << " w" << std::dec << static_cast<unsigned>(top.debug_wb_rf_wnum)
                      << "=0x" << std::hex << top.debug_wb_rf_wdata
                      << std::dec << "\n";
            ++trace_crn_count;
            if (stop_after_trace_crn && trace_crn_count >= trace_crn_limit) {
                dump_ext_ram(top, dump_ext_addr, dump_ext_size);
                if (!compare_ext_file.empty()) {
                    compare_pass = compare_ext_ram(top, compare_ext_addr,
                                                   compare_ext_file, compare_ext_size,
                                                   compare_mismatch_limit);
                }
                break;
            }
        }

        if (clk_posedge && ext_log_enable && top.ext_ram_write_fire) {
            uint32_t byte_addr = static_cast<uint32_t>(top.ext_ram_write_addr) << 2;
            bool in_log_range = !ext_log_range_enable ||
                                (byte_addr >= ext_log_start && byte_addr < ext_log_end);
            if (ext_log_all || in_log_range) {
                if (ext_log_count < ext_log_limit) {
                    uint32_t phys = 0x1c400000u + (static_cast<uint32_t>(top.ext_ram_write_addr) << 2);
                    std::cout << "[EXT_W] t=" << main_time
                              << " word_addr=" << std::hex << top.ext_ram_write_addr
                              << " phys=" << phys
                              << " be=" << (~top.ext_ram_write_be_n & 0xf)
                              << " data=" << top.ext_ram_write_data
                              << std::dec << "\n";
                } else if (!ext_log_truncated) {
                    std::cout << "[EXT_W] log truncated at " << ext_log_limit
                              << " writes; use +ext_ram_write_log_limit=<N> to raise the limit\n";
                    ext_log_truncated = true;
                }
                ++ext_log_count;
            }
        }

        if (clk_posedge && top.uart_display) {
            uint8_t ch = top.uart_data;
            if (term_mode) {
                if (!term_bridge.send_byte(ch)) {
                    term_disconnected = true;
                    break;
                }
                term_tracker.consume_output(ch, main_time);
            } else if (supervisor_uart_check) {
                switch (uart_check_phase) {
                case UartCheckPhase::WaitWelcome:
                    if (ch >= 0x20 && ch <= 0x7e) {
                        std::cout << static_cast<char>(ch) << std::flush;
                    }
                    if (ch == static_cast<uint8_t>(kWelcome[welcome_match])) {
                        ++welcome_match;
                        if (kWelcome[welcome_match] == '\0') {
                            pending_command = PendingCommand::LoadAndReadback;
                            send_scheduled = true;
                            send_time = main_time + 20 * kUartBitTime;
                        }
                    } else {
                        welcome_match =
                            (ch == static_cast<uint8_t>(kWelcome[0])) ? 1 : 0;
                    }
                    break;
                case UartCheckPhase::LoadReadback:
                    uart_response.push_back(ch);
                    if (uart_response.size() == supervisor_program_bytes.size()) {
                        uart_check_pass = compare_uart_bytes(
                            "A/D program readback", uart_response,
                            supervisor_program_bytes);
                        if (uart_check_pass) {
                            pending_command = PendingCommand::Run;
                            send_scheduled = true;
                            send_time = main_time + 20 * kUartBitTime;
                        } else {
                            uart_check_phase = UartCheckPhase::Done;
                            uart_check_done = true;
                        }
                    }
                    break;
                case UartCheckPhase::WaitProgramStart:
                    if (ch == 0x06) {
                        supervisor_started = true;
                        uart_check_phase = UartCheckPhase::ProgramRunning;
                        std::cout << "[TB] Supervisor program started.\n"
                                  << std::flush;
                    } else if (ch == 0x80) {
                        std::cerr << "[TB] Supervisor rejected G command\n";
                        uart_check_pass = false;
                        uart_check_phase = UartCheckPhase::Done;
                        uart_check_done = true;
                    }
                    break;
                case UartCheckPhase::ProgramRunning:
                    if (ch == 0x07) {
                        std::cout << "[TB] Supervisor program finished.\n"
                                  << std::flush;
                        pending_command = PendingCommand::ReadRegisters;
                        send_scheduled = true;
                        send_time = main_time + 20 * kUartBitTime;
                    } else if (ch == 0x80) {
                        std::cerr << "[TB] Supervisor reported program failure\n";
                        uart_check_pass = false;
                        uart_check_phase = UartCheckPhase::Done;
                        uart_check_done = true;
                    } else if (ch >= 0x20 && ch <= 0x7e) {
                        std::cout << static_cast<char>(ch) << std::flush;
                    }
                    break;
                case UartCheckPhase::RegisterReadback:
                    uart_response.push_back(ch);
                    if (uart_response.size() == 124U) {
                        uart_check_pass = compare_uart_registers(
                            uart_response, supervisor_expected_regs);
                        if (uart_check_pass) {
                            pending_command = PendingCommand::ReadResult;
                            send_scheduled = true;
                            send_time = main_time + 20 * kUartBitTime;
                        } else {
                            uart_check_phase = UartCheckPhase::Done;
                            uart_check_done = true;
                        }
                    }
                    break;
                case UartCheckPhase::ResultReadback:
                    uart_response.push_back(ch);
                    if (uart_response.size() == supervisor_result_bytes.size()) {
                        uart_check_pass = compare_uart_bytes(
                            "D result memory", uart_response,
                            supervisor_result_bytes);
                        uart_check_phase = UartCheckPhase::Done;
                        uart_check_done = true;
                        if (uart_check_pass) {
                            std::cout << "[TB] Supervisor UART self-check PASS\n"
                                      << std::flush;
                        }
                    }
                    break;
                case UartCheckPhase::Disabled:
                case UartCheckPhase::Done:
                    break;
                }
                if (uart_check_done) {
                    break;
                }
            } else {
                if (ch >= 0x20 && ch <= 0x7e) {
                    std::cout << static_cast<char>(ch) << std::flush;
                }

                if (supervisor_g_sent && ch == 0x06) {
                    supervisor_started = true;
                    std::cout << "\n[TB] Supervisor program started.\n" << std::flush;
                } else if (supervisor_started && ch == 0x07) {
                    std::cout << "\n[TB] Supervisor program finished.\n" << std::flush;
                    dump_ext_ram(top, dump_ext_addr, dump_ext_size);
                    if (!compare_ext_file.empty()) {
                        compare_pass = compare_ext_ram(top, compare_ext_addr,
                                                       compare_ext_file,
                                                       compare_ext_size,
                                                       compare_mismatch_limit);
                    }
                    break;
                }

                if (!supervisor_g_sent) {
                    if (ch == static_cast<uint8_t>(kWelcome[welcome_match])) {
                        ++welcome_match;
                        if (kWelcome[welcome_match] == '\0') {
                            pending_command = PendingCommand::LegacyRun;
                            send_scheduled = true;
                            send_time = main_time + 20 * kUartBitTime;
                        }
                    } else {
                        welcome_match =
                            (ch == static_cast<uint8_t>(kWelcome[0])) ? 1 : 0;
                    }
                }
            }
        }
    }

    top.final();
    if (difftest_on) {
        difftest_finish();
    }
    if (wave_enable) {
        wave.close();
    }
    if (term_mode && term_disconnected) {
        return term_bridge.failed() ? 1 : 0;
    }
    if (!term_mode && main_time >= max_time) {
        std::cerr << "[TB] Timeout at t=" << main_time << "\n";
        if (difftest_on) difftest_finish();
        difftest_dump_state();
        return 1;
    }
    if (supervisor_uart_check && !uart_check_done) {
        std::cerr << "[TB] Supervisor UART self-check ended unexpectedly\n";
        return 1;
    }
    if (!uart_check_pass) {
        return 1;
    }
    if (!compare_pass) {
        return 1;
    }
    return 0;
}
