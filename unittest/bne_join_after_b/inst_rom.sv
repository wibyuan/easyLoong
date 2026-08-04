module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data,
    output logic [31:0] data1
);
    logic [31:0] rom [0:15];
    initial begin
        rom[0] = 32'h143e000d;
        rom[1] = 32'h038011ad;
        rom[2] = 32'h0380000e;
        rom[3] = 32'h288001ac;
        rom[4] = 32'h0340818c;
        rom[5] = 32'h028005ce;
        rom[6] = 32'h5c000980;
        rom[7] = 32'h53fff3ff;
        rom[8] = 32'h1c000037;
        rom[9] = 32'h03815414;
        rom[10] = 32'h50000000;
    end
    assign data  = rom[addr[6:2]];
    assign data1 = rom[addr[6:2] + 32'd1];
endmodule
