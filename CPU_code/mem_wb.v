module mem_wb(
	input 	wire 					clk,
	input 	wire 					rst,
	input 	wire 					rdy,

	// from mem
	input	wire[`RegAddrBus]		mem_wd,
	input	wire					mem_wreg,
	input	wire[`RegBus]			mem_wdata,

	// to wb
	output 	reg[`RegAddrBus]		wb_wd,
	output	reg 					wb_wreg,
	output 	reg[`RegBus]			wb_wdata,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
		end else if(stall_sign[7]) begin
			// STALL
		end else begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
		end
	end

endmodule