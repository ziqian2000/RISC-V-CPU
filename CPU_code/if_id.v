module if_id(
	input	wire					clk,
	input 	wire 					rst,
	// from IF
	input 	wire[`InstAddrBus] 		if_pc,
	input	wire[`InstBus]			if_inst,
	// to ID
	output	reg[`InstAddrBus]		id_pc,
	output	reg[`InstBus]			id_inst,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

always @(posedge clk) begin
	if (rst == `RstEnable) begin
		id_pc <= `ZeroWord;		
		id_inst <= `ZeroWord;
	end else if(stall_sign[1] && !stall_sign[2]) begin
		id_inst <= 0;
	end else if(stall_sign[1]) begin
		// STALL
	end	else begin
		id_pc <= if_pc;
		id_inst <= if_inst;
	end
end

endmodule