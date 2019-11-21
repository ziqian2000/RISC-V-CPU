module ex(
	input	wire 				rst,

	// from id_ex
	input	wire[`OpcodeBus]	opcode_i,
	input	wire[`RegBus]		reg1_i,
	input	wire[`RegBus]		reg2_i,
	input	wire[`RegAddrBus]	wd_i,
	input	wire				wreg_i,

	// to ex_mem
	output 	reg[`RegAddrBus] 	wd_o,
	output	reg 				wreg_o,
	output	reg[`RegBus]		wdata_o
);
	// execute
	always @ (*) begin
		if(rst == `RstEnable) begin
			wdata_o <= 0;
		end else begin
			case(opcode_i[6:0])


				7'b0110011, 7'b0010011: begin 	//ADD,SUB,SLL,SLT,SLTU,XOR,SRL,SRA,OR,AND
												//ADDI,SLTI,SLTIU,XORI,ORI,ANDI,SLLI,SRLI,SRAI
					case(opcode_i[10:7])
						4'b0000: wdata_o <= (reg1_i + reg2_i); 								// ADD(I)
						4'b1000: wdata_o <= (reg1_i - reg2_i); 								// SUB
						4'b0001: wdata_o <= (reg1_i << reg2_i[4:0]); 						// SLL(I)
						4'b0010: wdata_o <= ($signed(reg1_i) < $signed(reg2_i));			// SLT(I)
						4'b0011: wdata_o <= (reg1_i < reg2_i); 								// SLT(I)U
						4'b0100: wdata_o <= (reg1_i ^ reg2_i); 								// XOR(I)
						4'b0101: wdata_o <= (reg1_i >> reg2_i[4:0]); 						// SRL(I)
						4'b1101: wdata_o <= 
							({reg1_i >> reg2_i[4:0]} | {32{reg1_i[31]}} << (~reg2_i[4:0])); // SRA(I)
						4'b0110: wdata_o <= (reg1_i | reg2_i); 								// OR(I)
						4'b0111: wdata_o <= (reg1_i & reg2_i); 								// AND(I)
					endcase
				end

				7'b0110111: begin 		//LUI
					wdata_o <= reg1_i;
				end
				7'b0010111: begin 		//AUIPC
					wdata_o <= reg1_i;
				end
				7'b1101111: begin 		//JAL
					wdata_o <= reg2_i;
				end
				7'b1100111: begin 		//JALR
					wdata_o <= reg2_i;
				end
				7'b1100011: begin	 	//BEQ,BNE,BLT,BGE,BLTU,BGEU	
					// nothing to do
				end
				7'b0000011: begin  		//LOAD
				end
				7'b0100011: begin  		//STORE
				end
				default: begin 			// something strange
				end

			endcase
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= 0;
			wreg_o <= 0;
		end else begin
			wd_o <= wd_i;
			wreg_o <= wreg_i;
		end
	end

endmodule 