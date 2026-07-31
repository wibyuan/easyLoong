module hazard_unit (
    input  logic        if_not_ready,
    input  logic        ex_not_ready,
    input  logic        lsu_not_ready,
    input  logic        cacop_not_ready,
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
    output logic        load_use_hazard,
    input  logic        jump_flush,
    input  logic        id_jump_req,
    input  logic        bp_do_jump,
    input  logic        wb_jump_req,
    input  logic [31:0] pc_current,
    input  logic [31:0] ex_jump_pc
);

    assign load_use_hazard = id_ex_mem_re &&
                            ((id_ex_rd != 5'd0) && ((id_ex_rd == dec_rs1) || (id_ex_rd == dec_rs2)));

    logic pipeline_stall;
    assign pipeline_stall = lsu_not_ready || cacop_not_ready || ex_not_ready;

    // If the EX redirect target equals the current fetch pc, the fetch_unit
    // suppresses its own redirect (the target is already being fetched) — the
    // if_id capture in that cycle IS the target, so the flush must not kill
    // it (mirrors the fetch_unit's pc_current != jump_target gating).
    logic jump_flush_keep_capture;
    assign jump_flush_keep_capture = jump_flush && (pc_current == ex_jump_pc);

    always_comb begin
        pc_stall     = pipeline_stall || load_use_hazard || if_not_ready;
        if_id_stall  = pipeline_stall || load_use_hazard || if_not_ready;
        id_ex_stall  = pipeline_stall;
        ex_mem_stall = pipeline_stall;

        id_ex_flush  = wb_jump_req || ( !(lsu_not_ready || cacop_not_ready || ex_not_ready) &&
                       (jump_flush || load_use_hazard || (if_not_ready && !id_jump_req && !bp_do_jump)) );

        if_id_flush  = wb_jump_req || ( !(lsu_not_ready || cacop_not_ready || ex_not_ready) &&
                       ((jump_flush && !jump_flush_keep_capture) ||
                        (id_jump_req && !id_ex_stall) || (bp_do_jump && !id_ex_stall)) );
    end

endmodule
