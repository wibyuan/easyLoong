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
        logic  data_ok;
        logic  data_last;
        word_t data;
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
