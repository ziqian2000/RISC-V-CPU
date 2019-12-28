module if_id(
	input	wire					clk,
	input 	wire 					rst,
	input 	wire 					rdy,
	// from IF
	input 	wire[`InstAddrBus] 		if_pc,
	input	wire[`InstBus]			if_inst,
	input 	wire 					if_taken,
	// to ID
	output	reg[`InstAddrBus]		id_pc,
	output	reg[`InstBus]			id_inst,
	output 	reg 					id_taken,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

always @(posedge clk) begin
	if (rst == `RstEnable || !rdy) begin
		id_pc 	<= `ZeroWord;		
		id_inst <= `ZeroWord;
		id_taken <= 0;
	end else if(stall_sign[1] && !stall_sign[2]) begin
		id_pc 	<= 0;
		id_inst <= 0;
		id_taken <= 0;
	end else if(stall_sign[1]) begin
		// STALL
	end	else begin
		id_pc <= if_pc;
		id_inst <= if_inst;
		id_taken <= if_taken;
	end
end

endmodule