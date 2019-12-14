module ex(
	input	wire 				rst,

	// from id_ex
	input	wire[`OpcodeBus]	opcode_i,
	input	wire[`RegBus]		reg1_i,
	input	wire[`RegBus]		reg2_i,
	input	wire[`RegAddrBus]	wd_i,
	input	wire				wreg_i,
	input 	wire[31:0] 			imm_i,
	input 	wire[`InstAddrBus] 	branch_addr_i,

	// to if
	output 	reg					branch_enable_o,
	output 	wire[`InstAddrBus]	branch_addr_o,

	// to ex_mem
	output 	reg[`RegAddrBus] 	wd_o,
	output	reg 				wreg_o,
	output	reg[`RegBus]		wdata_o,
	output 	reg[`InstAddrBus] 	mem_addr,
	output 	wire[`OpcodeBus] 	opcode_o,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

	wire 				reg1_eq_reg2;
	wire 				reg1_lt_reg2_u;
	wire 				reg1_gt_reg2_u;
	wire 				reg1_mux;
	wire 				reg2_mux;
	wire 				reg1_lt_reg2; 		// reg1 < reg2

	assign opcode_o = opcode_i;
	assign branch_addr_o = branch_addr_i;

	assign reg1_eq_reg2 = (reg1_i == reg2_i);
	assign reg1_lt_reg2_u = reg1_i < reg2_i;
	assign reg1_gt_reg2_u = reg1_i > reg2_i;
	assign reg1_mux = ~reg1_i + 32'h1;
	assign reg2_mux = ~reg2_i + 32'h1;
	assign reg1_lt_reg2 = ((reg1_i[31] & !reg2_i[31]) // neg < pos
	                    || (reg1_i[31] && reg2_i[31] && (reg1_mux > reg2_mux)) // neg neg use abs
	                    || (!reg1_i[31] && !reg2_i[31] && reg1_lt_reg2_u)); // pos pos compare


	// execute
	always @ (*) begin
		if(rst == `RstEnable) begin
			wdata_o = 0;
			branch_enable_o = 0;
			mem_addr = 0;
		end else begin
			case(opcode_i[6:0])

				7'b0110011: begin 	//ADD,SUB,SLL,SLT,SLTU,XOR,SRL,SRA,OR,AND
					case(opcode_i[10:7])
						4'b0000: wdata_o = (reg1_i + reg2_i); 								// ADD
						4'b1000: wdata_o = (reg1_i - reg2_i); 								// SUB
						4'b0001: wdata_o = (reg1_i << reg2_i[4:0]); 						// SLL
						4'b0010: wdata_o = reg1_lt_reg2;									// SLT
						4'b0011: wdata_o = (reg1_i < reg2_i); 								// SLTU
						4'b0100: wdata_o = (reg1_i ^ reg2_i); 								// XOR
						4'b0101: wdata_o = (reg1_i >> reg2_i[4:0]); 						// SRL
						4'b1101: wdata_o =  												// SRA
							({reg1_i >> reg2_i[4:0]} | {32{reg1_i[31]}} << (~reg2_i[4:0]));
						4'b0110: wdata_o = (reg1_i | reg2_i); 								// OR
						4'b0111: wdata_o = (reg1_i & reg2_i); 								// AND
						default: wdata_o = 0;
					endcase
					branch_enable_o = 0;
					mem_addr = 0;
				end

				7'b0010011: begin 	//ADDI,SLTI,SLTIU,XORI,ORI,ANDI,SLLI,SRLI,SRAI    almost the same as above
					case(opcode_i[9:7])
						3'b000: wdata_o = (reg1_i + reg2_i); 								// ADDI
						3'b001: wdata_o = (reg1_i << reg2_i[4:0]); 							// SLLI
						3'b010: wdata_o = reg1_lt_reg2;										// SLTI
						3'b011: wdata_o = (reg1_i < reg2_i); 								// SLTIU
						3'b100: wdata_o = (reg1_i ^ reg2_i); 								// XORI
						3'b101: begin
							case(opcode_i[10])
								1'b0: wdata_o = (reg1_i >> reg2_i[4:0]); 						// SRLI
								1'b1: wdata_o =  												// SRAI
									({reg1_i >> reg2_i[4:0]} | {32{reg1_i[31]}} << (~reg2_i[4:0]));
							endcase
						end
						3'b110: wdata_o = (reg1_i | reg2_i); 								// ORI
						3'b111: wdata_o = (reg1_i & reg2_i); 								// ANDI
						default: wdata_o = 0;
					endcase
					branch_enable_o = 0;
					mem_addr = 0;
				end

				7'b0110111: begin 		//LUI
					branch_enable_o = 0;
					wdata_o = reg1_i;
					mem_addr = 0;
				end
				7'b0010111: begin 		//AUIPC
					branch_enable_o = 0;
					wdata_o = reg1_i;
					mem_addr = 0;
				end
				7'b1101111: begin 		//JAL
					branch_enable_o = 1'b1;
					wdata_o = reg2_i;
					mem_addr = 0;
				end
				7'b1100111: begin 		//JALR
					branch_enable_o = 1'b1;
					wdata_o = reg2_i;
					mem_addr = 0;
				end
				7'b1100011: begin	 	//BEQ,BNE,BLT,BGE,BLTU,BGEU	
					case(opcode_i[9:7])
						3'b000: begin // BEQ
							if(reg1_i == reg2_i) begin
								branch_enable_o	= 1'b1;
							end else branch_enable_o = 0;
						end
						3'b001: begin // BNE
							if(reg1_i != reg2_i) begin
								branch_enable_o	= 1'b1;
							end else branch_enable_o = 0;
						end
						3'b100: begin // BLT
							if(reg1_lt_reg2) begin
								branch_enable_o	= 1'b1;
							end else branch_enable_o = 0;
						end
						3'b101: begin // BGE
							if(!reg1_lt_reg2) begin
								branch_enable_o	= 1'b1;
							end else branch_enable_o = 0;
						end
						3'b110: begin // BLTU
							if(reg1_i < reg2_i) begin
								branch_enable_o	= 1'b1;
							end else branch_enable_o = 0;
						end
						3'b111: begin // BGEU
							if(reg1_i >= reg2_i) begin
								branch_enable_o	= 1'b1;
							end else branch_enable_o = 0;
						end
						default: begin
							branch_enable_o = 0;
						end	
					endcase
					mem_addr = 0;
					wdata_o = 0;
				end
				7'b0000011: begin  		//LOAD
					branch_enable_o = 0;
					mem_addr = reg1_i + imm_i;
					wdata_o = 0;
				end
				7'b0100011: begin  		//STORE
					branch_enable_o = 0;
					mem_addr = reg1_i + imm_i;
					wdata_o = reg2_i;
				end
				default: begin 			// something strange
					branch_enable_o = 0;
					wdata_o = 0;
					mem_addr = 0;
				end

			endcase
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o = 0;
			wreg_o = 0;
		end else begin
			wd_o = wd_i;
			wreg_o = wreg_i;
		end
	end

endmodule 