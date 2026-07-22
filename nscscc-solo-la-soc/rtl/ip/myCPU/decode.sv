`include "common.sv"

module decode import la32_common::*; (
    input  logic [31:0] instr,
    output logic [4:0]  rs1, rs2, rd,
    output logic        rf_we,
    output logic [31:0] imm,
    output alu_op_t     alu_op,
    output logic        alu_src_sel,
    output logic        is_word_op,
    output logic        mem_we,
    output logic        mem_re,
    output msize_t      mem_size,
    output logic        mem_unsigned,
    output logic        is_branch,
    output logic        is_jal,
    output logic        is_jalr,
    output br_type_t    br_type,
    output logic        is_pcadd,
    output logic        is_cpucfg,
    output logic        is_illegal
);

    logic [5:0]  op6;
    logic [9:0]  op10;
    logic [16:0] op17;

    assign op6  = instr[31:26];
    assign op10 = instr[31:22];
    assign op17 = instr[31:15];

    assign rs1 = instr[9:5];

    always_comb begin
        rs2         = instr[14:10];
        rd          = instr[4:0];
        rf_we       = 1'b0;
        alu_op      = ALU_ADD;
        alu_src_sel = 1'b0;
        is_word_op  = 1'b1;
        imm         = 32'd0;
        mem_we      = 1'b0;
        mem_re      = 1'b0;
        mem_size    = MSIZE4;
        mem_unsigned = 1'b0;
        is_branch   = 1'b0;
        is_jal      = 1'b0;
        is_jalr     = 1'b0;
        br_type     = BR_NONE;
        is_pcadd    = 1'b0;
        is_cpucfg   = 1'b0;
        is_illegal  = 1'b1;

        casez (instr)
            // ==================== 2RI12-type: immediate ALU ====================
            32'b0000001000_????????????_?????_?????: begin // SLTI
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SLT;
                alu_src_sel = 1'b1;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0000001001_????????????_?????_?????: begin // SLTUI
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SLTU;
                alu_src_sel = 1'b1;
                imm = {20'd0, instr[21:10]};
            end
            32'b0000001010_????????????_?????_?????: begin // ADDI.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0000001101_????????????_?????_?????: begin // ANDI
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_AND;
                alu_src_sel = 1'b1;
                imm = {20'd0, instr[21:10]};
            end
            32'b0000001110_????????????_?????_?????: begin // ORI
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_OR;
                alu_src_sel = 1'b1;
                imm = {20'd0, instr[21:10]};
            end
            32'b0000001111_????????????_?????_?????: begin // XORI
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_XOR;
                alu_src_sel = 1'b1;
                imm = {20'd0, instr[21:10]};
            end

            // ==================== 3R-type: register ALU ====================
            32'b00000000000100000_?????_?????_?????: begin // ADD.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_ADD;
            end
            32'b00000000000100010_?????_?????_?????: begin // SUB.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SUB;
            end
            32'b00000000000100100_?????_?????_?????: begin // SLT
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SLT;
            end
            32'b00000000000100101_?????_?????_?????: begin // SLTU
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SLTU;
            end
            32'b00000000000101000_?????_?????_?????: begin // NOR
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_NOR;
            end
            32'b00000000000101001_?????_?????_?????: begin // AND
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_AND;
            end
            32'b00000000000101010_?????_?????_?????: begin // OR
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_OR;
            end
            32'b00000000000101011_?????_?????_?????: begin // XOR
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_XOR;
            end
            32'b00000000000101110_?????_?????_?????: begin // SLL.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SLL;
            end
            32'b00000000000101111_?????_?????_?????: begin // SRL.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SRL;
            end
            32'b00000000000110000_?????_?????_?????: begin // SRA.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SRA;
            end
            32'b00000000000111000_?????_?????_?????: begin // MUL.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_MUL;
            end

            // ==================== 2RI5-type: shift immediate ====================
            32'b0000000001000000_1_?????_?????_?????: begin // SLLI.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SLL;
                alu_src_sel = 1'b1;
                imm = {27'd0, instr[14:10]};
            end
            32'b0000000001000100_1_?????_?????_?????: begin // SRLI.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SRL;
                alu_src_sel = 1'b1;
                imm = {27'd0, instr[14:10]};
            end
            32'b0000000001001000_1_?????_?????_?????: begin // SRAI.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_SRA;
                alu_src_sel = 1'b1;
                imm = {27'd0, instr[14:10]};
            end

            // ==================== 2RI12-type: loads ====================
            32'b0010100000_????????????_?????_?????: begin // LD.B
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_re = 1'b1;
                mem_size = MSIZE1;
                mem_unsigned = 1'b0;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0010100001_????????????_?????_?????: begin // LD.H
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_re = 1'b1;
                mem_size = MSIZE2;
                mem_unsigned = 1'b0;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0010100010_????????????_?????_?????: begin // LD.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_re = 1'b1;
                mem_size = MSIZE4;
                mem_unsigned = 1'b0;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0010101000_????????????_?????_?????: begin // LD.BU
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_re = 1'b1;
                mem_size = MSIZE1;
                mem_unsigned = 1'b1;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0010101001_????????????_?????_?????: begin // LD.HU
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_re = 1'b1;
                mem_size = MSIZE2;
                mem_unsigned = 1'b1;
                imm = {{20{instr[21]}}, instr[21:10]};
            end

            // ==================== 2RI12-type: stores ====================
            32'b0010100100_????????????_?????_?????: begin // ST.B
                is_illegal = 1'b0;
                rs2 = instr[4:0];
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_we = 1'b1;
                mem_size = MSIZE1;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0010100101_????????????_?????_?????: begin // ST.H
                is_illegal = 1'b0;
                rs2 = instr[4:0];
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_we = 1'b1;
                mem_size = MSIZE2;
                imm = {{20{instr[21]}}, instr[21:10]};
            end
            32'b0010100110_????????????_?????_?????: begin // ST.W
                is_illegal = 1'b0;
                rs2 = instr[4:0];
                alu_op = ALU_ADD;
                alu_src_sel = 1'b1;
                mem_we = 1'b1;
                mem_size = MSIZE4;
                imm = {{20{instr[21]}}, instr[21:10]};
            end

            // ==================== LU12I.W / PCADDU12I ====================
            32'b0001010_????????????????????_?????: begin // LU12I.W
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_LUI;
                alu_src_sel = 1'b1;
                imm = {instr[24:5], 12'd0};
            end
            32'b0001110_????????????????????_?????: begin // PCADDU12I
                is_illegal = 1'b0;
                rf_we = 1'b1;
                alu_op = ALU_PCADD;
                alu_src_sel = 1'b1;
                is_pcadd = 1'b1;
                imm = {instr[24:5], 12'd0};
            end

            // ==================== JIRL ====================
            32'b010011_????????????????_?????_?????: begin // JIRL
                is_illegal = 1'b0;
                rf_we = 1'b1;
                is_jalr = 1'b1;
                imm = {{16{instr[25]}}, instr[25:10]};
            end

            // ==================== B / BL ====================
            32'b010100_????????????????_??????????: begin // B
                is_illegal = 1'b0;
                is_branch = 1'b1;
                br_type = BR_NONE;
                imm = {{4{instr[9]}}, instr[9:0], instr[25:10], 2'd0};
            end
            32'b010101_????????????????_??????????: begin // BL
                is_illegal = 1'b0;
                rd = 5'd1;
                is_jal = 1'b1;
                rf_we = 1'b1;
                imm = {{4{instr[9]}}, instr[9:0], instr[25:10], 2'd0};
            end

            // ==================== Branch instructions ====================
            32'b010110_????????????????_?????_?????: begin // BEQ
                is_illegal = 1'b0;
                is_branch = 1'b1;
                br_type = BR_BEQ;
                rs2 = instr[4:0];
                imm = {{14{instr[25]}}, instr[25:10], 2'd0};
            end
            32'b010111_????????????????_?????_?????: begin // BNE
                is_illegal = 1'b0;
                is_branch = 1'b1;
                br_type = BR_BNE;
                rs2 = instr[4:0];
                imm = {{14{instr[25]}}, instr[25:10], 2'd0};
            end
            32'b011000_????????????????_?????_?????: begin // BLT
                is_illegal = 1'b0;
                is_branch = 1'b1;
                br_type = BR_BLT;
                rs2 = instr[4:0];
                imm = {{14{instr[25]}}, instr[25:10], 2'd0};
            end
            32'b011001_????????????????_?????_?????: begin // BGE
                is_illegal = 1'b0;
                is_branch = 1'b1;
                br_type = BR_BGE;
                rs2 = instr[4:0];
                imm = {{14{instr[25]}}, instr[25:10], 2'd0};
            end
            32'b011010_????????????????_?????_?????: begin // BLTU
                is_illegal = 1'b0;
                is_branch = 1'b1;
                br_type = BR_BLTU;
                rs2 = instr[4:0];
                imm = {{14{instr[25]}}, instr[25:10], 2'd0};
            end
            32'b011011_????????????????_?????_?????: begin // BGEU
                is_illegal = 1'b0;
                is_branch = 1'b1;
                br_type = BR_BGEU;
                rs2 = instr[4:0];
                imm = {{14{instr[25]}}, instr[25:10], 2'd0};
            end

            // ==================== CPUCFG ====================
            32'b00000000000000000_11011_?????_?????: begin // CPUCFG
                is_illegal = 1'b0;
                rf_we = 1'b1;
                is_cpucfg = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
