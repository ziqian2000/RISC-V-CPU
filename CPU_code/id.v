module id(
	input	wire					rst,
	input	wire[`InstAddrBus]		pc_i,
	input	wire[`InstBus]			inst_i,

	// from regfile
	input	wire[`RegBus] 			reg1_data_i,
	input	wire[`RegBus] 			reg2_data_i,

	// to regfile
	output	reg 					reg1_read_o,
	output	reg 					reg2_read_o,
	output	reg[`RegAddrBus]		reg1_addr_o,
	output	reg[`RegAddrBus]		reg2_addr_o,

	// to id_ex
	output	reg[`OpcodeBus]			opcode_o,
	output	reg[`RegBus]			reg1_o,
	output	reg[`RegBus]			reg2_o,
	output	reg[`RegAddrBus]		wd_o,
	output	reg 					wreg_o
);

reg[`RegBus] imm;

reg instvalid;

// decoding

always @(*) begin
	if(rst == `RstEnable) begin
		opcode_o 	<= 10'b00000000000;
		wd_o 		<= `NOPRegAddr;
		wreg_o		<= `WriteDisable;
		instvalid	<= `InstValid;
		reg1_read_o <= 1'b0;
		reg2_read_o <= 1'b0;
		reg1_addr_o <= `NOPRegAddr;
		reg2_addr_o <= `NOPRegAddr;
		imm			<= 32'h0;
	end else begin
		instvalid	= `InstValid;

		reg1_read_o = 1'b0;
		reg2_read_o = 1'b0;
		wreg_o		= 1'b0;

		reg1_addr_o = inst_i[19:15];// rs1
		reg2_addr_o = inst_i[24:20];// rs2
		wd_o 		= inst_i[11:7];	// rd

		imm			= `ZeroWord;

		case (inst_i[6:0])
			7'b0110011: begin 		//ADD,SUB,SLL,SLT,SLTU,XOR,SRL,SRA,OR,AND
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o	= 1'b1;
				reg2_read_o	= 1'b1;
				wreg_o		= 1'b1;
			end
			7'b0110111: begin 		//LUI
			end
			7'b0010111: begin 		//AUIPC
			end
			7'b0010011: begin 		//ADDI,SLTI,SLTIU,XORI,ORI,ANDI,SLLI,SRLI,SRAI
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o	= 1'b1;
				reg2_read_o	= 1'b0;
				wreg_o		= 1'b1;
				imm			= {{21{inst_i[31]}}, inst_i[31:20]};
			end
			7'b1101111: begin 		//JAL
			end
			7'b1100111: begin 		//JALR
			end
			7'b1100011: begin	 	//B
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

// operand 1

always @(*) begin
	if (rst == `RstEnable) begin
		reg1_o <= `ZeroWord;
	end else if(reg1_read_o == 1'b1) begin
		reg1_o <= reg1_data_i;
	end else if(reg1_read_o == 1'b0) begin
		reg1_o <= imm;
	end else begin
		reg1_o <= `ZeroWord;
	end
end

// operand 2

always @(*) begin
	if (rst == `RstEnable) begin
		reg2_o <= `ZeroWord;
	end else if(reg2_read_o == 1'b1) begin
		reg2_o <= reg2_data_i;
	end else if(reg2_read_o == 1'b0) begin
		reg2_o <= imm;
	end else begin
		reg2_o <= `ZeroWord;
	end
end

endmodule