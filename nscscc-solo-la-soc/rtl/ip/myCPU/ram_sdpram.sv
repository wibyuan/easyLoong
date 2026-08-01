// Parameterized simple-dual-port RAM (one write port + one read port),
// modeled after rvcpu's RAM_SimpleDualPort: the read latency is a
// parameter, and the ram_style follows from it:
//   READ_LATENCY = 0: combinational (asynchronous) read -> distributed
//                     RAM (LUTRAM).  Used for the cache tag arrays and the
//                     icache data, where the hit/data must be available in
//                     the request cycle.
//   READ_LATENCY = 1: registered read -> block RAM (BRAM).  Used for the
//                     dcache data: the 0-cycle hit ack comes from the
//                     asynchronous tag read, while the data completes one
//                     cycle later and is sampled by the WB stage, so the
//                     data arrays stay BRAM-inferrable.
// Byte-lane writes are selected with the strobe vector (BYTE_WIDTH-wide
// lanes); a full-word write uses all-ones strobe.

module ram_sdpram #(
    parameter int ADDR_WIDTH   = 8,
    parameter int DATA_WIDTH   = 32,
    parameter int BYTE_WIDTH   = 8,
    parameter int READ_LATENCY = 0
) (
    input  logic                    clk,
    input  logic [ADDR_WIDTH-1:0]   raddr,
    input  logic [ADDR_WIDTH-1:0]   waddr,
    input  logic                    en,
    input  logic [DATA_WIDTH/BYTE_WIDTH-1:0] strobe,
    input  logic [DATA_WIDTH-1:0]   wdata,
    output logic [DATA_WIDTH-1:0]   rdata
);

    localparam int NUM_WORDS      = 2 ** ADDR_WIDTH;
    localparam int BYTES_PER_WORD = DATA_WIDTH / BYTE_WIDTH;

    // Cannot use a parameter-dependent attribute value portably; elaborate
    // the array inside a generate branch so the ram_style is a literal.
    generate
        if (READ_LATENCY == 0) begin : g_dist
            (* ram_style = "distributed" *) logic [DATA_WIDTH-1:0] mem [NUM_WORDS-1:0];

            always_ff @(posedge clk) begin
                if (en)
                    for (int i = 0; i < BYTES_PER_WORD; i++)
                        if (strobe[i])
                            mem[waddr][BYTE_WIDTH*i +: BYTE_WIDTH] <=
                                wdata[BYTE_WIDTH*i +: BYTE_WIDTH];
            end

            assign rdata = mem[raddr];
        end else begin : g_block
            (* ram_style = "block" *) logic [DATA_WIDTH-1:0] mem [NUM_WORDS-1:0];

            always_ff @(posedge clk) begin
                if (en)
                    for (int i = 0; i < BYTES_PER_WORD; i++)
                        if (strobe[i])
                            mem[waddr][BYTE_WIDTH*i +: BYTE_WIDTH] <=
                                wdata[BYTE_WIDTH*i +: BYTE_WIDTH];
            end

            always_ff @(posedge clk)
                rdata <= mem[raddr];
        end
    endgenerate

endmodule
