module id_ex(
	input	wire 				clk,
	input	wire 				rst,

	// from id
	input 	wire[`OpcodeBus]	id_opcode,
	input	wire[`RegBus]		id_reg1,
	input	wire[`RegBus]		id_reg2,
	input	wire[`RegAddrBus]	id_wd,
	input	wire				id_wreg,
	input 	wire[31:0] 			id_imm,

	// to ex
	output	reg[`OpcodeBus]		ex_opcode,
	output	reg[`RegBus]		ex_reg1,
	output	reg[`RegBus]		ex_reg2,
	output	reg[`RegAddrBus]	ex_wd,
	output	reg 				ex_wreg,
	output  reg[31:0] 			ex_imm,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

always @(posedge clk) begin
	if (rst == `RstEnable) begin

		ex_opcode <= 0;
		ex_reg1 <= `ZeroWord;
		ex_reg2 <= `ZeroWord;
		ex_wd <= `NOPRegAddr;
		ex_wreg <= `WriteDisable;
	end else if(stall_sign[3]) begin
		// STALL
	end else begin

		/* 	preprocess for instr of opcode 0010011 so that  stage EX can be easier 
		 * 	as 0010011 instr and 0110011 instr are almost the same
		 */
		if(id_opcode[6:0] == 7'b0010011 && id_opcode[9:7] != 3'b001 && id_opcode[9:7] != 3'b101 ) begin
			ex_opcode <= (id_opcode);
		end else begin
			ex_opcode <= id_opcode;
		end

		ex_reg1 <= id_reg1;
		ex_reg2 <= id_reg2;
		ex_wd <= id_wd;
		ex_wreg <= id_wreg;
	end
end

endmodule