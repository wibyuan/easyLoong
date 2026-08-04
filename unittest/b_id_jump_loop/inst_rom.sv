module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data,
    output logic [31:0] data1
);
    logic [31:0] rom [0:31];
    initial begin
        rom[0] = 32'h038fa00c;
        rom[1] = 32'h14388004;
        rom[2] = 32'h0381540d;
        rom[3] = 32'h03800017;
        rom[4] = 32'h03800018;
        rom[5] = 32'h0014d1ae;
        rom[6] = 32'h004089ce;
        rom[7] = 32'h0010388f;
        rom[8] = 32'h288001f0;
        rom[9] = 32'h0015c1ad;
        rom[10] = 32'h004095b1;
        rom[11] = 32'h0015c5ad;
        rom[12] = 32'h00449db1;
        rom[13] = 32'h0015c5ad;
        rom[14] = 32'h034005b1;
        rom[15] = 32'h58000e20;
        rom[16] = 32'h001042f7;
        rom[17] = 32'h50000800;
        rom[18] = 32'h0015c318;
        rom[19] = 32'h298001ed;
        rom[20] = 32'h02bffd8c;
        rom[21] = 32'h5fffc180;
        rom[22] = 32'h03815414;
        rom[23] = 32'h50000000;
    end
    assign data  = rom[addr[6:2]];
    assign data1 = rom[addr[6:2] + 32'd1];
endmodule
