module hazard_unit (
    input  logic        if_not_ready,
    input  logic        ex_not_ready,
    input  logic        lsu_not_ready,
    input  logic        cacop_not_ready,
    input  logic [4:0]  id_ex0_rd,
    input  logic        id_ex0_mem_re,
    input  logic [4:0]  id_ex1_rd,
    input  logic        id_ex1_mem_re,
    input  logic [4:0]  dec_rs1_0,
    input  logic [4:0]  dec_rs2_0,
    input  logic [4:0]  dec_rs1_1,
    input  logic [4:0]  dec_rs2_1,
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
    input  logic        fq_head_valid,
    input  logic [31:0] fq_head_pc,
    input  logic [31:0] pc_current,
    input  logic [31:0] ex_jump_pc,
    input  logic [31:0] id_jump_pc,
    input  logic [31:0] bp_jump_pc
);

    // A load in either EX slot feeding any ID slot operand: the load data
    // is not available until MEM, so the pipeline is held (legacy
    // single-issue semantics; slot1 re-issues next cycle as slot0).
    assign load_use_hazard =
        (id_ex0_mem_re && (id_ex0_rd != 5'd0) &&
         ((dec_rs1_0 == id_ex0_rd) || (dec_rs2_0 == id_ex0_rd) ||
          (dec_rs1_1 == id_ex0_rd) || (dec_rs2_1 == id_ex0_rd))) ||
        (id_ex1_mem_re && (id_ex1_rd != 5'd0) &&
         ((dec_rs1_0 == id_ex1_rd) || (dec_rs2_0 == id_ex1_rd) ||
          (dec_rs1_1 == id_ex1_rd) || (dec_rs2_1 == id_ex1_rd)));

    assign pipeline_stall = lsu_not_ready || cacop_not_ready || ex_not_ready;

    // The legacy EX-redirect capture protection is disabled for the
    // 2-wide core: the fetch queue absorbs (space-gated) rather than
    // overwrites, so after a flush the fetch re-delivers the target on the
    // next cycle (pc held by the queue-full stall, or the redirect already
    // moving pc to the target).  Keeping the queue would instead leave
    // stale wrong-path instructions ahead of the target (observed: the
    // wrong-path b executed after the bne redirect) or duplicate the
    // target when the fetch re-delivers it.  The single-issue capture
    // (if_id register, flush-overwrites) never had these two effects.
    logic jump_flush_keep_capture;
    assign jump_flush_keep_capture = 1'b0;

    always_comb begin
        pc_stall     = pipeline_stall || load_use_hazard || if_not_ready;
        if_id_stall  = pipeline_stall || load_use_hazard || if_not_ready;
        id_ex_stall  = pipeline_stall;
        ex_mem_stall = pipeline_stall;

        // The legacy single-issue "kill the ID->EX entry on a fetch stall"
        // term (if_not_ready && !id_jump_req && !bp_do_jump) is gone: with
        // the fetch queue the ID->EX entries that already left the queue
        // must NOT be rolled back — an ex_mem-stalled stage would then lose
        // the instruction entirely (observed: the unconditional B and JIRL
        // killed while their EX->MEM capture was held by a store write).
        // The Bug-7 re-issue gate (id_ex0_in.ctrl.valid, core.sv) already
        // prevents re-decoding a held queue head.
        id_ex_flush  = wb_jump_req || ( !(lsu_not_ready || cacop_not_ready || ex_not_ready) &&
                       (jump_flush || load_use_hazard) );

        // id_jump/bp redirects flush the wrong-path queue head, but must
        // not kill the branch instruction itself: when the load_use hazard
        // holds the branch in ID (its ID->EX entry was already flushed), the
        // queue head still contains the branch — flushing it destroys the
        // instruction while the fetch continues down the predicted path.
        // The fetch_unit mirrors the redirect with a pc_current != jump_target
        // suppression, so the in-flight capture is the target when the fetch
        // is already there; the fetch queue absorbs that in-flight target as
        // the new head (see the FQ flush path in core.sv) instead of being
        // discarded — the wrong-path entries behind the branch are dropped.
        if_id_flush  = wb_jump_req || ( !(lsu_not_ready || cacop_not_ready || ex_not_ready) &&
                       ((jump_flush && !jump_flush_keep_capture) ||
                        (id_jump_req && !id_ex_stall && !load_use_hazard) ||
                        (bp_do_jump && (pc_current != bp_jump_pc) && !id_ex_stall && !load_use_hazard)) );
    end

endmodule
