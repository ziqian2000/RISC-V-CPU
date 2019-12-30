module id_ex(
	input	wire 				clk,
	input	wire 				rst,
	input 	wire 				rdy,

	// from id
	input 	wire[`OpcodeBus]	id_opcode,
	input	wire[`RegBus]		id_reg1,
	input	wire[`RegBus]		id_reg2,
	input	wire[`RegAddrBus]	id_wd,
	input	wire				id_wreg,
	input 	wire[31:0] 			id_imm,
	input 	wire[`InstAddrBus]	id_branch_addr_t,
	input 	wire[`InstAddrBus]	id_branch_addr_n,
	input 	wire 				id_taken,

	// to ex
	output	reg[`OpcodeBus]		ex_opcode,
	output	reg[`RegBus]		ex_reg1,
	output	reg[`RegBus]		ex_reg2,
	output	reg[`RegAddrBus]	ex_wd,
	output	reg 				ex_wreg,
	output  reg[31:0] 			ex_imm,
	output 	reg[`InstAddrBus]	ex_branch_addr_t,
	output 	reg[`InstAddrBus]	ex_branch_addr_n,
	output 	reg 				ex_taken,

	// from ctrl
	input 	wire[`StallBus] 	stall_sign
);

always @(posedge clk) begin
	if (rst == `RstEnable) begin

		ex_opcode <= 0;
		ex_reg1 <= `ZeroWord;
		ex_reg2 <= `ZeroWord;
		ex_wd <= `NOPRegAddr;
		ex_wreg <= `WriteDisable;
		ex_imm <= 0;
		ex_branch_addr_t <= 0;
		ex_branch_addr_n <= 0;
		ex_taken 		<= 0;
		
	end else if(stall_sign[2] && !stall_sign[3]) begin

		ex_opcode <= 0;
		ex_reg1 <= `ZeroWord;
		ex_reg2 <= `ZeroWord;
		ex_wd <= `NOPRegAddr;
		ex_wreg <= `WriteDisable;
		ex_imm <= 0;
		ex_branch_addr_t <= 0;
		ex_branch_addr_n <= 0;
		ex_taken 		<= 0;

	end else if(stall_sign[3] && !stall_sign[4]) begin

		ex_opcode <= 0;
		ex_reg1 <= `ZeroWord;
		ex_reg2 <= `ZeroWord;
		ex_wd <= `NOPRegAddr;
		ex_wreg <= `WriteDisable;
		ex_imm <= 0;
		ex_branch_addr_t <= 0;
		ex_branch_addr_n <= 0;
		ex_taken 		<= 0;
		
	end else if(stall_sign[3]) begin
		// STALL
	end else begin
	
		ex_opcode <= id_opcode;
		ex_reg1 <= id_reg1;
		ex_reg2 <= id_reg2;
		ex_wd <= id_wd;
		ex_wreg <= id_wreg;
		ex_imm <= id_imm;
		ex_branch_addr_t <= id_branch_addr_t;
		ex_branch_addr_n <= id_branch_addr_n;
		ex_taken 		 <= id_taken;
	end
end

endmodule