module regfile (
    input  logic        clk,
    input  logic [4:0]  ra1, ra2,
    output logic [31:0] rd1, rd2,
    input  logic [4:0]  wa,
    input  logic [31:0] wd,
    input  logic        wen,
    output logic [31:0] gpr_dbg [31:0]
);

    logic [31:0] regs [31:0];

    always_ff @(posedge clk) begin
        if (wen && wa != 5'd0)
            regs[wa] <= wd;
    end

    assign rd1 = (ra1 == 5'd0) ? 32'd0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : regs[ra2];

    always_comb begin
        for (int i = 0; i < 32; i++) begin
            if (wen && wa == 5'(i) && i != 0)
                gpr_dbg[i] = wd;
            else
                gpr_dbg[i] = regs[i];
        end
    end

endmodule
