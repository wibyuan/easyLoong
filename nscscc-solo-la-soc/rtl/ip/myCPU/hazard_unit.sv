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
    output logic        pipeline_stall,
    input  logic        jump_flush,
    input  logic        id_jump_req,
    input  logic        bp_do_jump,
    input  logic        wb_jump_req,
    input  logic        if_id_in_valid,
    input  logic [31:0] if_id_in_pc,
    input  logic [31:0] pc_current,
    input  logic [31:0] ex_jump_pc,
    input  logic [31:0] id_jump_pc,
    input  logic [31:0] bp_jump_pc
);

    assign load_use_hazard = id_ex_mem_re &&
                            ((id_ex_rd != 5'd0) && ((id_ex_rd == dec_rs1) || (id_ex_rd == dec_rs2)));

    assign pipeline_stall = lsu_not_ready || cacop_not_ready || ex_not_ready;

    // If the EX redirect target equals the current fetch pc, the fetch_unit
    // suppresses its own redirect (the target is already being fetched) — the
    // if_id capture in that cycle IS the target, so the flush must not kill
    // it. The pc_current equality alone is not sufficient: the fetch can
    // reach the target address while the if_id still holds the branch's
    // fall-through captured one cycle earlier (e.g. the branch at the last
    // word of a line whose fall-through is the sequential pc+4 equal to the
    // target). Only keep the capture when it really is the target.
    logic jump_flush_keep_capture;
    assign jump_flush_keep_capture = jump_flush && (pc_current == ex_jump_pc) &&
                                     if_id_in_valid && (if_id_in_pc == ex_jump_pc);

    always_comb begin
        pc_stall     = pipeline_stall || load_use_hazard || if_not_ready;
        if_id_stall  = pipeline_stall || load_use_hazard || if_not_ready;
        id_ex_stall  = pipeline_stall;
        ex_mem_stall = pipeline_stall;

        id_ex_flush  = wb_jump_req || ( !(lsu_not_ready || cacop_not_ready || ex_not_ready) &&
                       (jump_flush || load_use_hazard || (if_not_ready && !id_jump_req && !bp_do_jump)) );

        // id_jump/bp redirects flush the wrong-path if_id capture, but must
        // not kill the branch instruction itself: when the load_use hazard
        // holds the branch in ID (its ID->EX entry was already flushed), the
        // if_id register still contains the branch — flushing it destroys the
        // instruction while the fetch continues down the predicted path.
        // Also mirror the fetch_unit's pc_current != jump_target redirect
        // suppression: when the fetch is already at the target, the if_id
        // capture in flight IS the target and must survive.
        if_id_flush  = wb_jump_req || ( !(lsu_not_ready || cacop_not_ready || ex_not_ready) &&
                       ((jump_flush && !jump_flush_keep_capture) ||
                        (id_jump_req && (pc_current != id_jump_pc) && !id_ex_stall && !load_use_hazard) ||
                        (bp_do_jump && (pc_current != bp_jump_pc) && !id_ex_stall && !load_use_hazard)) );
    end

endmodule
