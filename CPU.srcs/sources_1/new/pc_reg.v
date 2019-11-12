module pc_reg(
	input	wire				clk,
	input	wire				rst,
	output	reg[`InstAddrBus]	pc
	// "ce" is not needed here as ram contains no "ce" as input
);

//always @(posedge clk) begin
//	if (rst == `RstEnable) begin
//		ce <= `ChipDisable;		
//	end
//	else begin
//		ce <= `ChipEnable;
//	end
//end

always @(posedge clk) begin
	if (rst == `RstEnable) begin
		pc <= 32'h00000000;	
	end	else begin
		pc <= pc + 4'h4;
	end
end

endmodule