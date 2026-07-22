module pipeline_reg #(
    parameter WIDTH = 32
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             stall,
    input  logic             flush,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);

    always_ff @(posedge clk) begin
        if (reset || flush)
            data_out <= '0;
        else if (!stall)
            data_out <= data_in;
    end

endmodule
