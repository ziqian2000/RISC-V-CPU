module ex_mem(
	input 	wire					clk,
	input 	wire					rst,

	// from ex
	input	wire[`RegAddrBus]		ex_wd,
	input	wire					ex_wreg,
	input	wire[`RegBus]			ex_wdata,
	input 	wire[`InstAddrBus] 		ex_mem_addr,
	input 	wire[`OpcodeBus] 		ex_opcode_i,

	// to mem
	output	reg[`RegAddrBus]		mem_wd,
	output 	reg 					mem_wreg,
	output 	reg[`RegBus]			mem_wdata,
	output 	reg[`InstAddrBus] 		mem_mem_addr,
	output  reg[`OpcodeBus] 		mem_opcode_o,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

always @(posedge clk) begin
	if (rst == `RstEnable) begin
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;
		mem_mem_addr <= 0;
		mem_opcode_o <= 0;
	// end else if(stall_sign[5] && !stall_sign[6]) begin
	// 	mem_wd <= `NOPRegAddr;
	// 	mem_wreg <= `WriteDisable;
	// 	mem_wdata <= `ZeroWord;
	// 	mem_mem_addr <= 0;
	// 	mem_opcode_o <= 0;
	end else if(!stall_sign[5]) begin
		mem_wd <= ex_wd;
		mem_wreg <= ex_wreg;
		mem_wdata <= ex_wdata;
		mem_mem_addr <= ex_mem_addr;
		mem_opcode_o <= ex_opcode_i;
	end
end

endmodule