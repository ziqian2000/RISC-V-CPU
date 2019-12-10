module id_ex(
	input wire				  clk,
	input wire				  rst,

	// ctrl signal
	input wire[`StallBus]	   stall_sign,

	// from ID
	input wire[`OpcodeBus]	  id_opcode,
	input wire[`FunctBus3]	  id_funct3,
	input wire[`FunctBus7]	  id_funct7,
	input wire[`RegBus]		 id_reg1,
	input wire[`RegBus]		 id_reg2,
	input wire[`RegBus]		 id_ls_offset,
	input wire[`RegAddrBus]	 id_wd,
	input wire				  id_wreg,

	// to EX
	output reg[`OpcodeBus]	  ex_opcode,
	output reg[`FunctBus3]	  ex_funct3,
	output reg[`FunctBus7]	  ex_funct7,
	output reg[`RegBus]		 ex_reg1,
	output reg[`RegBus]		 ex_reg2,
	output reg[`RegBus]		 ex_ls_offset,
	output reg[`RegAddrBus]	 ex_wd,
	output reg				  ex_wreg

);

	always @ (posedge clk) begin
		if (rst) begin
			ex_opcode	   <= `NON_OP;
			ex_funct3	   <= `NON_FUNCT3;
			ex_funct7	   <= `NON_FUNCT7;
			ex_reg1		 <= `ZeroWord;
			ex_reg2		 <= `ZeroWord;
			ex_ls_offset	<= `ZeroWord;
			ex_wd		   <= `NOPRegAddr;
			ex_wreg		 <= `WriteDisable;
		end else if (stall_sign[3] && !stall_sign[4]) begin
			ex_opcode	   <= `NON_OP;
			ex_funct3	   <= `NON_FUNCT3;
			ex_funct7	   <= `NON_FUNCT7;
			ex_reg1		 <= `ZeroWord;
			ex_reg2		 <= `ZeroWord;
			ex_ls_offset	<= `ZeroWord;
			ex_wd		   <= `NOPRegAddr;
			ex_wreg		 <= `WriteDisable;
		end else if (!stall_sign[3]) begin
			ex_opcode	   <= id_opcode;
			ex_funct3	   <= id_funct3;
			ex_funct7	   <= id_funct7;
			ex_reg1		 <= id_reg1;
			ex_reg2		 <= id_reg2;
			ex_ls_offset	<= id_ls_offset;
			ex_wd		   <= id_wd;
			ex_wreg		 <= id_wreg;
		end
	end

endmodule // id_ex
