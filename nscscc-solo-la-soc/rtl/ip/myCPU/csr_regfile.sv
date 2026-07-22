module csr_regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic [13:0] csr_num,
    output logic [31:0] csr_rdata,
    input  logic        csr_we,
    input  logic [13:0] csr_waddr,
    input  logic [31:0] csr_wdata,
    output logic [31:0] crmd,
    output logic [31:0] dmw0,
    output logic [31:0] dmw1,
    output logic [31:0] prmd,
    output logic [31:0] euen,
    output logic [31:0] ecfg,
    output logic [31:0] estat,
    output logic [31:0] era,
    output logic [31:0] badv,
    output logic [31:0] eentry,
    output logic [31:0] tlbidx,
    output logic [31:0] tlbehi,
    output logic [31:0] tlbelo0,
    output logic [31:0] tlbelo1,
    output logic [31:0] asid,
    output logic [31:0] pgdl,
    output logic [31:0] pgdh,
    output logic [31:0] save0,
    output logic [31:0] save1,
    output logic [31:0] save2,
    output logic [31:0] save3,
    output logic [31:0] tid,
    output logic [31:0] tcfg,
    output logic [31:0] tval,
    output logic [31:0] llbctl,
    output logic [31:0] tlbrentry
);

    logic [31:0] csr [0:511];

    initial begin
        csr[14'h000] = 32'h00000008;
        csr[14'h018] = 32'h000A0000;
    end

    always_comb begin
        csr_rdata = 32'd0;
        case (csr_num)
            14'h004: csr_rdata = csr[14'h004];
            14'h005: csr_rdata = csr[14'h005];
            14'h006: csr_rdata = csr[14'h006];
            14'h007: csr_rdata = csr[14'h007];
            14'h00c: csr_rdata = csr[14'h00c];
            14'h010: csr_rdata = csr[14'h010];
            14'h011: csr_rdata = csr[14'h011];
            14'h012: csr_rdata = csr[14'h012];
            14'h013: csr_rdata = csr[14'h013];
            14'h018: csr_rdata = csr[14'h018];
            14'h019: csr_rdata = csr[14'h019];
            14'h01a: csr_rdata = csr[14'h01a];
            14'h030: csr_rdata = csr[14'h030];
            14'h031: csr_rdata = csr[14'h031];
            14'h032: csr_rdata = csr[14'h032];
            14'h033: csr_rdata = csr[14'h033];
            14'h040: csr_rdata = csr[14'h040];
            14'h041: csr_rdata = csr[14'h041];
            14'h042: csr_rdata = csr[14'h042];
            14'h060: csr_rdata = csr[14'h060];
            14'h088: csr_rdata = csr[14'h088];
            14'h180: csr_rdata = csr[14'h180];
            14'h181: csr_rdata = csr[14'h181];
            14'h000: csr_rdata = csr[14'h000];
            14'h001: csr_rdata = csr[14'h001];
            14'h002: csr_rdata = csr[14'h002];
            default:  csr_rdata = 32'd0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            csr[14'h000] <= 32'h00000008;
            csr[14'h001] <= 32'd0;
            csr[14'h002] <= 32'd0;
            csr[14'h004] <= 32'd0;
            csr[14'h005] <= 32'd0;
            csr[14'h006] <= 32'd0;
            csr[14'h007] <= 32'd0;
            csr[14'h00c] <= 32'd0;
            csr[14'h010] <= 32'd0;
            csr[14'h011] <= 32'd0;
            csr[14'h012] <= 32'd0;
            csr[14'h013] <= 32'd0;
            csr[14'h018] <= 32'h000A0000;
            csr[14'h019] <= 32'd0;
            csr[14'h01a] <= 32'd0;
            csr[14'h030] <= 32'd0;
            csr[14'h031] <= 32'd0;
            csr[14'h032] <= 32'd0;
            csr[14'h033] <= 32'd0;
            csr[14'h040] <= 32'd0;
            csr[14'h041] <= 32'd0;
            csr[14'h042] <= 32'd0;
            csr[14'h060] <= 32'd0;
            csr[14'h088] <= 32'd0;
            csr[14'h180] <= 32'd0;
            csr[14'h181] <= 32'd0;
        end else if (csr_we) begin
            case (csr_waddr)
                14'h000: csr[14'h000] <= csr_wdata;
                14'h001: csr[14'h001] <= csr_wdata;
                14'h002: csr[14'h002] <= csr_wdata;
                14'h004: csr[14'h004] <= csr_wdata;
                14'h005: csr[14'h005] <= csr_wdata;
                14'h006: csr[14'h006] <= csr_wdata;
                14'h007: csr[14'h007] <= csr_wdata;
                14'h00c: csr[14'h00c] <= csr_wdata;
                14'h010: csr[14'h010] <= csr_wdata;
                14'h011: csr[14'h011] <= csr_wdata;
                14'h012: csr[14'h012] <= csr_wdata;
                14'h013: csr[14'h013] <= csr_wdata;
                14'h018: csr[14'h018] <= csr_wdata;
                14'h019: csr[14'h019] <= csr_wdata;
                14'h01a: csr[14'h01a] <= csr_wdata;
                14'h030: csr[14'h030] <= csr_wdata;
                14'h031: csr[14'h031] <= csr_wdata;
                14'h032: csr[14'h032] <= csr_wdata;
                14'h033: csr[14'h033] <= csr_wdata;
                14'h040: csr[14'h040] <= csr_wdata;
                14'h041: csr[14'h041] <= csr_wdata;
                14'h042: csr[14'h042] <= csr_wdata;
                14'h060: csr[14'h060] <= csr_wdata;
                14'h088: csr[14'h088] <= csr_wdata;
                14'h180: csr[14'h180] <= csr_wdata;
                14'h181: csr[14'h181] <= csr_wdata;
            endcase
        end
    end

    assign crmd      = csr[14'h000];
    assign prmd      = csr[14'h001];
    assign euen      = csr[14'h002];
    assign ecfg      = csr[14'h004];
    assign estat     = csr[14'h005];
    assign era       = csr[14'h006];
    assign badv      = csr[14'h007];
    assign eentry    = csr[14'h00c];
    assign tlbidx    = csr[14'h010];
    assign tlbehi    = csr[14'h011];
    assign tlbelo0   = csr[14'h012];
    assign tlbelo1   = csr[14'h013];
    assign asid      = csr[14'h018];
    assign pgdl      = csr[14'h019];
    assign pgdh      = csr[14'h01a];
    assign save0     = csr[14'h030];
    assign save1     = csr[14'h031];
    assign save2     = csr[14'h032];
    assign save3     = csr[14'h033];
    assign tid       = csr[14'h040];
    assign tcfg      = csr[14'h041];
    assign tval      = csr[14'h042];
    assign llbctl    = csr[14'h060];
    assign tlbrentry = csr[14'h088];
    assign dmw0      = csr[14'h180];
    assign dmw1      = csr[14'h181];

endmodule
