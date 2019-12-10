module stage_ex(
    input wire                  rst,
    input wire                  rdy,

    // read from id_ex
    input wire[`OpcodeBus]      opcode_i,
    input wire[`FunctBus3]      funct3_i,
    input wire[`FunctBus7]      funct7_i,
    input wire[`RegBus]         reg1_i,
    input wire[`RegBus]         reg2_i,
    input wire[`RegBus]         ls_offset_i,
    input wire[`RegAddrBus]     wd_i,
    input wire                  wreg_i,
    input wire[`StallBus]       stall_sign,

    // output the result of ex
    output reg[`OpcodeBus]      opcode_o,
    output reg[`FunctBus3]      funct3_o,
    output reg[`InstAddrBus]    mem_addr_o,
    output reg[`RegAddrBus]     wd_o,
    output reg                  wreg_o,
    output reg[`RegBus]         wdata_o
);

    reg[`RegBus]        op_imm_res;
    reg[`RegBus]        op_op_res;

    wire                reg1_eq_reg2; // if reg1 == reg2, thisi is 1'b1;
    wire                reg1_lt_reg2; // if reg1 < reg2, this is 1'b1;
    wire[`RegBus]       reg2_i_mux;   // reg2's two's complement representation;
    wire[`RegBus]       result_sum;
    wire[`RegBus]       shift_sra;

    assign reg1_eq_reg2 = reg1_i == reg2_i;
    assign reg2_i_mux = ((funct7_i == `SUB_FUNCT7) ||
                        (funct3_i ==  `SLT_FUNCT3))? (~reg2_i) + 1 : reg2_i;
    assign result_sum = reg1_i + reg2_i_mux;
    assign reg1_lt_reg2 = (funct3_i == `SLT_FUNCT3)? ((reg1_i[31] & !reg2_i[31])
                        || (!reg1_i[31] && !reg2_i[31] && result_sum[31])
                        || (reg1_i[31] && reg2_i[31] && result_sum[31])):
                        (reg1_i < reg2_i);
    assign shift_sra = ({32{reg1_i[31]}} << (6'd32 - {1'b0, reg2_i[4:0]})) | reg1_i >> reg2_i[4:0];

    always @ ( * ) begin
        if (rst) begin
            wd_o        <= `ZeroWord;
            wreg_o      <= `WriteDisable;
            wdata_o     <= `ZeroWord;
            opcode_o    <= `NON_OP;
            funct3_o    <= `NON_FUNCT3;
            mem_addr_o  <= `ZeroWord;
        end else begin
            wd_o        <= wd_i;
            wreg_o      <= wreg_i;
            wdata_o     <= `ZeroWord;
            opcode_o    <= opcode_i;
            funct3_o    <= funct3_i;
            mem_addr_o  <= `ZeroWord;
            case (opcode_i)
                `OP_IMM_OP: begin
                    case (funct3_i)
                        `ADDI_FUNCT3: begin
                            wdata_o  <= result_sum;
                        end
                        `ORI_FUNCT3: begin
                            wdata_o  <= reg1_i | reg2_i;
                        end
                        `XORI_FUNCT3: begin
                            wdata_o  <= reg1_i ^ reg2_i;
                        end
                        `ANDI_FUNCT3: begin
                            wdata_o <= reg1_i & reg2_i;
                        end
                        default: begin
                        end
                    endcase
                end
                `OP_OP: begin
                    case (funct3_i)
                        `ADD_SUB_FUNCT3: begin
                            wdata_o <= result_sum;
                        end
                        `SLT_FUNCT3, `SLTU_FUNCT3: begin
                            wdata_o <= reg1_lt_reg2;
                        end
                        `OR_FUNCT3: begin
                            wdata_o <= reg1_i | reg2_i;
                        end
                        `XOR_FUNCT3: begin
                            wdata_o <= reg1_i ^ reg2_i;
                        end
                        `AND_FUNCT3: begin
                            wdata_o <= reg1_i & reg2_i;
                        end
                        `SLL_FUNCT3: begin
                            wdata_o <= reg1_i << reg2_i[4:0];
                        end
                        `SRL_SRA_FUNCT3: begin
                            case (funct7_i)
                                `SRL_FUNCT7: begin
                                    wdata_o <= reg1_i >> reg2_i[4:0];
                                end
                                `SRA_FUNCT7: begin
                                    wdata_o <= shift_sra;
                                end
                                default: begin
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                `LOAD_OP: begin
                    mem_addr_o  <= reg1_i + ls_offset_i;
                end
                `STORE_OP: begin
                    mem_addr_o  <= reg1_i + ls_offset_i;
                    wdata_o     <= reg2_i;
                end
                `LUI_OP: begin
                    wdata_o <= reg1_i;
                end
                `AUIPC_OP: begin
                    wdata_o <= reg1_i;
                end
                `JAL_OP: begin
                    wdata_o <= reg1_i;
                end
                `JALR_OP: begin
                    wdata_o <= reg2_i;
                end
                `BRANCH_OP: begin
                end
                default: begin
                    wdata_o <= `ZeroWord;
                end
            endcase
        end
    end

endmodule // ex
