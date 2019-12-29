// a central controller to control the whole process by stalling some stages when necessary

module ctrl(
	input      wire 					clk,
	input      wire 					rst,
	input 	   wire						rdy,

	// from id
	input      wire 					id_stall_request,

	// from mem
	input      wire 					mem_stall_request,

	// from ex
	input 		wire 					branch_stall_request,

	output     reg[`StallBus] 			stall_sign
	// 	7		6		5		4		3		2		1		0
	// MEM/WB 	MEM 	EX/MEM 	EX 		ID/EX 	ID 		IF/ID 	IF
);

always @(*) begin
	// stall_sign = 0;
	if(rst == `RstEnable) begin
		stall_sign = 0;
	end else if(!rdy) begin
		stall_sign = 8'b11111111;
	end else begin
		if(mem_stall_request) begin
			stall_sign = 8'b00111111;
		end else if(branch_stall_request) begin
			stall_sign = 8'b00001010;
		end else if(id_stall_request) begin
			stall_sign = 8'b00000111;
		end else begin
			stall_sign = 8'b00000000;
		end
	end
end


endmodule