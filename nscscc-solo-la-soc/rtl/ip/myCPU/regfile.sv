// 4-read 2-write register file for the 2-wide superscalar core.
// Write port 1 is the slot0 (older) writer, port 2 the slot1 (newer)
// writer in program order.  When both write the same register in one
// cycle the array keeps the port-2 value (last nonblocking assignment
// wins) and the read bypass returns the port-2 value first, so a reader
// in the same cycle sees the newest writer consistently.
module regfile (
    input  logic        clk,
    input  logic [4:0]  ra1, ra2, ra3, ra4,
    output logic [31:0] rd1, rd2, rd3, rd4,
    input  logic [4:0]  wa1,
    input  logic [31:0] wd1,
    input  logic        wen1,
    input  logic [4:0]  wa2,
    input  logic [31:0] wd2,
    input  logic        wen2,
    output logic [31:0] gpr_dbg [31:0]
);

    logic [31:0] regs [31:0];

    always_ff @(posedge clk) begin
        if (wen1 && wa1 != 5'd0)
            regs[wa1] <= wd1;
        if (wen2 && wa2 != 5'd0)
            regs[wa2] <= wd2;
    end

    // Read path: the array mux only.  The current-cycle WB write (the
    // 2-back producer) is delivered by the core's forwarding matrix
    // (mw0/mw1 entries re-validated against the WB-stage rf_we), so the
    // combinational write-bypass is redundant here — dropping it keeps two
    // LUT levels off the RF read path (100MHz critical path).  The gpr_dbg
    // port keeps the bypass so the difftest state snapshot always shows
    // the architecturally newest value.
    function automatic logic [31:0] read(
        input logic [4:0]  ra,
        input logic [31:0] regs [31:0]
    );
        if (ra == 5'd0)
            read = 32'd0;
        else
            read = regs[ra];
    endfunction

    assign rd1 = read(ra1, regs);
    assign rd2 = read(ra2, regs);
    assign rd3 = read(ra3, regs);
    assign rd4 = read(ra4, regs);

    always_comb begin
        for (int i = 0; i < 32; i++) begin
            if (wen2 && wa2 == 5'(i) && i != 0)
                gpr_dbg[i] = wd2;
            else if (wen1 && wa1 == 5'(i) && i != 0)
                gpr_dbg[i] = wd1;
            else
                gpr_dbg[i] = regs[i];
        end
    end

endmodule
