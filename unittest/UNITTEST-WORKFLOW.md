# Unit Testing Workflow — From difftest Failure to Standalone Unit Test

本文档描述了当 `make test-*` difftest 报错时，如何将错误状态提取为独立单元测试的完整工作流。

---

## 1. 捕获错误现场

运行完整的 difftest 测试，收集错误信息：

```bash
make test-simple   # 或 make test-stream / test-matrix / ...
```

关注 difftest 输出的三个关键部分：

| 输出段 | 提取信息 |
|--------|---------|
| `Commit Instr Trace` | 出错 PC、违例指令编码、违例提交模式（重复/缺失） |
| `Register Diff` | 哪个寄存器不匹配、DUT vs REF 的值 |
| `REF Regs` / `DUT Regs` | 出错时刻的全量寄存器快照（GPR + CSR + PC） |

---

## 2. 提取指令序列

从 `kernel.s`（disassembly）中截取出错 PC 附近的指令序列。此处需要获取两项：

### 2.1 出错代码段的反汇编

```bash
grep -A10 -B5 "<出错PC>" sdk/software/examples/supervisor/build/kernel/auto/kernel.s
```

如果是循环体，需要提取完整循环（含跳转指令），因为 flush 行为依赖于循环结构。

### 2.2 寄存器初始化状态

从 difftest 输出的 `REF Regs` 段中提取寄存器值。如果错误发生在循环深处，可能只需初始化循环入口的几个关键寄存器即可。

---

## 3. 编写最小汇编程序

创建一个 `.s` 文件，包含：

1. **寄存器初始化指令**（将关键寄存器设为目标值）
2. **跳转到循环入口**
3. **循环体**（从 kernel.s 截取，保持原指令和地址偏移关系）
4. **结束标记**（如 `b .` 死循环）

```asm
    .text
    .globl _start
_start:
    ori   $r14, $r0, 0x1
    slli.w $r14, $r14, 8        # r14 = 0x100
    ori   $r15, $r0, 0x4        # r15 = 4
    ori   $r17, $r0, 0x1        # r17 = 1
    b     loop_entry

loop_entry:
    # ... 从 kernel.s 复制的循环体 ...

end_loop:
    b     end_loop
```

**约束**：`PCINIT = 0x1c000000`。程序从该地址开始执行，总指令数尽量少（跳过 supervisor 等无关节）。

---

## 4. 汇编并生成 binary

```bash
TOOLDIR=nscscc-solo-la-soc/sdk/toolchains/.../bin
$TOOLDIR/loongarch32r-linux-gnusf-as -o test_prog.o test_prog.s
$TOOLDIR/loongarch32r-linux-gnusf-ld -Ttext=0x1c000000 -o test_prog.elf test_prog.o
$TOOLDIR/loongarch32r-linux-gnusf-objcopy -O binary test_prog.elf test_prog.bin
$TOOLDIR/loongarch32r-linux-gnusf-objdump -d test_prog.elf   # 验证地址和编码
```

---

## 5. 编写指令 ROM

创建 `inst_rom.sv`：组合逻辑 ROM，提供 0-cycle 指令读取。**所有 ROM 内容必须与 `test_prog.bin` 逐字节一致**（使用 objdump 输出验证）。

```systemverilog
module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom [0:15];
    initial begin
        rom[0] = 32'h0380040e;  // ori $r14,$r0,0x1
        rom[1] = 32'h0040a1ce;  // slli.w $r14,$r14,0x8
        // ... 与 objdump 一致 ...
    end
    assign data = rom[addr[5:2]];
endmodule
```

---

## 6. 编写 testbench

创建 `test_tb.sv`：实例化 `core` 模块，提供：

| 接口 | 配置 |
|------|------|
| `iresp` | 0-cycle 响应（`addr_ok=1`，`data_ok` 来自 inst_rom） |
| `dresp` | 始终 ready（无实际访存时可行） |
| `cacop_done` | 立即完成（非 cache 测试时可简化） |
| `data_ok_en` | reset 释放后延迟 1 拍使能，让 fetch_unit 完成 IDLE→REQ |

**关键设计决策 — `data_ok_en`**：真实 icache 在上电后有 S_INIT 延迟，确保 fetch_unit 进入 REQ 状态后才有 data_ok。纯组合逻辑 ROM 需要在 testbench 端复制此延迟，否则第一条指令 (PCINIT) 会因 fetch_unit 状态未就绪而丢失。

---

## 7. 编写 C++ harness

创建 `test_main.cpp`，集成 difftest：

1. 加载 `test_prog.bin` → `difftest_set_program()`
2. `difftest_init(NEMU_SO)` 连接 NEMU 参考模型
3. 驱动时钟（reset → 释放 → toggle）
4. 每 posedge 调用 `difftest_step()`，由 difftest 引擎比对 DUT vs NEMU
5. difftest 在 mismatch 时自动打印 diff 并 `exit(1)`

**DPI-C**：difftest.v 中的 DPI-C 模块（`DifftestInstrCommit` 等）由 core.sv 在 `ifdef VERILATOR` 下实例化，需链接 `difftest_interface.cpp` 和 `difftest_dut.cpp`。

---

## 8. 构建与运行脚本

创建 `run_test.sh`：

```bash
verilator --cc --exe --build \
    --top-module test_ex_mem_flush \
    -I${MYCPU_DIR} -I${RTL_DIR} -I${DIFFTEST_DIR} -I${ROOT_DIR} \
    test_tb.sv inst_rom.sv \
    ${MYCPU_DIR}/*.sv \
    test_main.cpp \
    ${DIFFTEST_DIR}/difftest_interface.cpp \
    ${DIFFTEST_DIR}/difftest_dut.cpp \
    -LDFLAGS "-ldl" -CFLAGS "-I${DIFFTEST_DIR} -I${ROOT_DIR}"
```

**增量构建**：用文件 SHA256 做 build stamp，仅在源文件变更时重编译。

---

## 9. 验证流程

```bash
cd unittest/ex_mem_flush
./run_test.sh
```

预期输出：
```
[DIFFTEST] initialized with .../la32r-nemu-interpreter-so, image test_prog.bin (60 bytes)
[difftest] state synced at startup
[difftest] mismatch at instruction #12
============== Register Diff ==============
...
```

**FAIL** 时 difftest 打印 register diff 并以 exit code 1 退出。  
**PASS** 时 difftest 正常结束（exit 0）或 timeout。

---

## 10. 与完整 difftest 的关系

| | 完整 difftest (make test-*) | 单元测试 |
|---|---|---|
| 启动开销 | supervisor init + 数十万指令 | ~10 条寄存器初始化 |
| 构建时间 | build-supervisor（含 base/ext RAM MIF） | 单文件汇编 + objcopy |
| 仿真时间 | 数秒至数分钟 | < 1 秒 |
| 复现稳定性 | 全系统交互（cache、UART、SRAM） | 仅 core + 最小指令集 |
| 适用场景 | 回归验证、集成测试 | 快速迭代、根因隔离 |

---
