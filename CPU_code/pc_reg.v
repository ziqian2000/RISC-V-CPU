module pc_reg(
	input	wire				clk,
	input	wire				rst,
	output	reg[`InstAddrBus]	pc,
	input 	wire[`InstAddrBus] 	pc_back
	// "ce" is not needed here as ram contains no "ce" as input
);

// always @(posedge clk) begin
// 	if (rst == `RstEnable) begin
// 		pc <= 32'h00000000;	
// 	end
// end

always @(*) begin
	if (rst == `RstEnable) begin
		pc <= 32'h00000000;	
	end else begin
		pc <= pc_back;
	end
end

endmodule