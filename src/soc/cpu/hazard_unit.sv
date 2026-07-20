module hazard_unit (
    input  logic        if_not_ready,
    input  logic        ex_not_ready,
    input  logic        lsu_not_ready,
    input  logic [4:0]  id_ex_rd,
    input  logic        id_ex_mem_re,
    input  logic [4:0]  dec_rs1,
    input  logic [4:0]  dec_rs2,
    output logic        pc_stall,
    output logic        if_id_stall,
    output logic        id_ex_stall,
    output logic        ex_mem_stall,
    output logic        if_id_flush,
    output logic        id_ex_flush,
    input  logic        jump_flush,
    input  logic        id_jump_req,
    input  logic        wb_jump_req
);

    logic load_use_hazard;
    assign load_use_hazard = id_ex_mem_re &&
                            ((id_ex_rd != 5'd0) && ((id_ex_rd == dec_rs1) || (id_ex_rd == dec_rs2)));

    assign if_id_flush = jump_flush || wb_jump_req || id_jump_req;
    assign id_ex_flush = jump_flush || wb_jump_req;

    assign pc_stall     = if_not_ready || load_use_hazard;
    assign if_id_stall  = if_not_ready || load_use_hazard || ex_not_ready;
    assign id_ex_stall  = ex_not_ready || lsu_not_ready;
    assign ex_mem_stall = lsu_not_ready;

endmodule
