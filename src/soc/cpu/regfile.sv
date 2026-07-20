module regfile (
    input  logic        clk,
    input  logic [4:0]  ra1, ra2,
    output logic [31:0] rd1, rd2,
    input  logic [4:0]  wa,
    input  logic [31:0] wd,
    input  logic        wen
);

    logic [31:0] gpr [31:0];

    always_ff @(posedge clk) begin
        if (wen && wa != 5'd0)
            gpr[wa] <= wd;
    end

    assign rd1 = (ra1 == 5'd0) ? 32'd0 : gpr[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : gpr[ra2];

endmodule
