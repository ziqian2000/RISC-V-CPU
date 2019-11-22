// a central controller to control the whole process by stalling some stages when necessary

module ctrl(
	input      wire 					clk,
	input      wire 					rst,

	input      wire 					mem_stall_request,

	output     reg[`StallBus] 			stall_sign
	// 	7		6		5		4		3		2		1		0
	//	IF 		IF/ID 	ID 		ID/EX 	EX 		EX/MEM 	MEM 	MEM/WB
);

always @(*) begin
	if(rst == `RstEnable) begin
		stall_sign <= 0;
	end else begin
		if(mem_stall_request) begin
			stall_sign <= 8'b11111100;
		end else begin
			stall_sign <= 8'b00000000;
		end
	end
end


endmodule