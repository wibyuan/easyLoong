`default_nettype none
`ifdef VERILATOR
module DifftestArchIntRegState (
    input  logic        clock,
    input  logic [31:0] gpr_0,  gpr_1,  gpr_2,  gpr_3,
    input  logic [31:0] gpr_4,  gpr_5,  gpr_6,  gpr_7,
    input  logic [31:0] gpr_8,  gpr_9,  gpr_10, gpr_11,
    input  logic [31:0] gpr_12, gpr_13, gpr_14, gpr_15,
    input  logic [31:0] gpr_16, gpr_17, gpr_18, gpr_19,
    input  logic [31:0] gpr_20, gpr_21, gpr_22, gpr_23,
    input  logic [31:0] gpr_24, gpr_25, gpr_26, gpr_27,
    input  logic [31:0] gpr_28, gpr_29, gpr_30, gpr_31
);
    import "DPI-C" function void v_difftest_ArchIntRegState(
        input int gpr_0,  input int gpr_1,  input int gpr_2,  input int gpr_3,
        input int gpr_4,  input int gpr_5,  input int gpr_6,  input int gpr_7,
        input int gpr_8,  input int gpr_9,  input int gpr_10, input int gpr_11,
        input int gpr_12, input int gpr_13, input int gpr_14, input int gpr_15,
        input int gpr_16, input int gpr_17, input int gpr_18, input int gpr_19,
        input int gpr_20, input int gpr_21, input int gpr_22, input int gpr_23,
        input int gpr_24, input int gpr_25, input int gpr_26, input int gpr_27,
        input int gpr_28, input int gpr_29, input int gpr_30, input int gpr_31
    );
    always @(posedge clock) begin
        v_difftest_ArchIntRegState(
            gpr_0,  gpr_1,  gpr_2,  gpr_3,  gpr_4,  gpr_5,  gpr_6,  gpr_7,
            gpr_8,  gpr_9,  gpr_10, gpr_11, gpr_12, gpr_13, gpr_14, gpr_15,
            gpr_16, gpr_17, gpr_18, gpr_19, gpr_20, gpr_21, gpr_22, gpr_23,
            gpr_24, gpr_25, gpr_26, gpr_27, gpr_28, gpr_29, gpr_30, gpr_31
        );
    end
endmodule

module DifftestInstrCommit (
    input  logic        clock,
    input  logic        valid,
    input  logic [31:0] pc,
    input  logic [31:0] instr,
    input  logic        wen,
    input  logic [4:0]  wdest,
    input  logic [31:0] wdata,
    input  logic [31:0] mem_addr,
    input  logic        mem_re
);
    import "DPI-C" function void v_difftest_InstrCommit(
        input int valid, input int pc, input int instr,
        input int wen, input int wdest, input int wdata,
        input int mem_addr, input int mem_re
    );
    always @(posedge clock) begin
        v_difftest_InstrCommit(valid, pc, instr, wen, wdest, wdata, mem_addr, mem_re);
    end
endmodule

module DifftestCSRState (
    input  logic        clock,
    input  logic [31:0] crmd, prmd, euen, ecfg,
    input  logic [31:0] era, badv, eentry,
    input  logic [31:0] tlbidx, tlbehi, tlbelo0, tlbelo1,
    input  logic [31:0] asid, pgdl, pgdh,
    input  logic [31:0] save0, save1, save2, save3,
    input  logic [31:0] tid, tcfg, tval,
    input  logic [31:0] llbctl, tlbrentry, dmw0, dmw1,
    input  logic [31:0] estat
);
    import "DPI-C" function void v_difftest_CSRState(
        input int crmd, input int prmd, input int euen, input int ecfg,
        input int era, input int badv, input int eentry,
        input int tlbidx, input int tlbehi, input int tlbelo0, input int tlbelo1,
        input int asid, input int pgdl, input int pgdh,
        input int save0, input int save1, input int save2, input int save3,
        input int tid, input int tcfg, input int tval,
        input int llbctl, input int tlbrentry, input int dmw0, input int dmw1,
        input int estat
    );
    always @(posedge clock) begin
        v_difftest_CSRState(
            crmd, prmd, euen, ecfg,
            era, badv, eentry,
            tlbidx, tlbehi, tlbelo0, tlbelo1,
            asid, pgdl, pgdh,
            save0, save1, save2, save3,
            tid, tcfg, tval,
            llbctl, tlbrentry, dmw0, dmw1,
            estat
        );
    end
endmodule

module DifftestIdlePC (
    input  logic        clock,
    input  logic [31:0] idle_pc
);
    import "DPI-C" function void v_difftest_IdlePC(input int idle_pc);
    always @(posedge clock) begin
        v_difftest_IdlePC(idle_pc);
    end
endmodule

module DifftestTrapEvent (
    input  logic        clock,
    input  logic        valid,
    input  logic [2:0]  code,
    input  logic [31:0] pc,
    input  logic [63:0] cycleCnt,
    input  logic [63:0] instrCnt
);
    import "DPI-C" function void v_difftest_TrapEvent(
        input int valid, input int code, input int pc,
        input longint cycleCnt, input longint instrCnt
    );
    always @(posedge clock) begin
        v_difftest_TrapEvent(valid, code, pc, cycleCnt, instrCnt);
    end
endmodule

module DifftestCacheState (
    input  logic        clock,
    input  logic [63:0] icache_access,
    input  logic [63:0] icache_hit,
    input  logic [63:0] icache_miss,
    input  logic [63:0] dcache_access,
    input  logic [63:0] dcache_hit,
    input  logic [63:0] dcache_miss,
    input  logic [63:0] dcache_writeback
);
    import "DPI-C" function void v_difftest_CacheState(
        input longint icache_access,
        input longint icache_hit,
        input longint icache_miss,
        input longint dcache_access,
        input longint dcache_hit,
        input longint dcache_miss,
        input longint dcache_writeback
    );
    always @(posedge clock) begin
        v_difftest_CacheState(icache_access, icache_hit, icache_miss,
                              dcache_access, dcache_hit, dcache_miss,
                              dcache_writeback);
    end
endmodule
`endif
