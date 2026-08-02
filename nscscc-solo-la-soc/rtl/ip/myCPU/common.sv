`ifndef __LA32_COMMON_SV
`define __LA32_COMMON_SV

package la32_common;

    parameter XLEN = 32;
    parameter PCINIT = 32'h1c000000;
    parameter LINK_REG = 1;

    typedef logic [31:0] word_t;
    typedef logic [4:0]  regid_t;

    typedef enum logic [3:0] {
        ALU_ADD, ALU_SUB,
        ALU_SLT, ALU_SLTU,
        ALU_AND, ALU_NOR, ALU_OR, ALU_XOR,
        ALU_SLL, ALU_SRL, ALU_SRA,
        ALU_LUI,
        ALU_PCADD,
        ALU_MUL
    } alu_op_t;

    typedef enum logic [2:0] {
        BR_NONE,
        BR_BEQ, BR_BNE,
        BR_BLT, BR_BGE, BR_BLTU, BR_BGEU
    } br_type_t;

    typedef enum logic [1:0] {
        MSIZE1 = 2'b00,
        MSIZE2 = 2'b01,
        MSIZE4 = 2'b10
    } msize_t;

    typedef struct packed {
        logic        valid;
        word_t       addr;
        msize_t      size;
        logic [3:0]  strobe;
        word_t       data;
        logic        cacheable;
        logic [1:0]  burst_len;
    } dbus_req_t;

    typedef struct packed {
        logic  addr_ok;
        // Read-channel data valid: set only when the READ channel returns
        // a beat.  data_ok is the combined read/write completion and must
        // not be used to qualify refill/keyword logic while a writeback
        // can be in flight (the write completion would corrupt the refill
        // data path).
        logic  rdata_ok;
        logic  data_ok;
        logic  data_last;
        word_t data;
        // Load hit answered through the data RAM's registered read port
        // (rvcpu-style 0-cycle hit): data_ok fires in the request cycle
        // (combinational tag hit) while the data completes one cycle
        // later on the registered read output.  The WB stage re-extracts
        // the full data port (dcache.data_wb) with the registered
        // instruction context instead of capturing it in the MEM stage.
        // hit_way carries the hit way so the WB selection is stable one
        // cycle after the request.  Misses/uncached/keyword completions
        // keep hit=0 and deliver data in-cycle as before.
        logic  hit;
        logic  hit_way;
    } dbus_resp_t;

    typedef struct packed {
        logic  valid;
        word_t addr;
    } ibus_req_t;

    typedef struct packed {
        logic  addr_ok;
        logic  data_ok;
        word_t data;
    } ibus_resp_t;

    typedef struct packed {
        logic       valid;
        logic [4:0] code;
        word_t      addr;
    } cacop_req_t;

endpackage

`endif
