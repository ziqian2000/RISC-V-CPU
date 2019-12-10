module ctrl (
	input wire					rst,
	input wire					rdy,

	input wire					if_stall_req_i,
	input wire					branch_stall_req_i,
	input wire					mem_stall_req_i,
	output reg[`StallBus]		stall_sign
);

// 	WB	 	MEM 	EX 		ID 		IF 		MEM_ACCESS 	IF_ACCESS
//	6		5		4		3		2		1			0

always @ ( * ) begin
	if (rst) begin
		stall_sign	<= 7'b0000000;
	end else if (!rdy) begin
		stall_sign	<= 7'b1111100;
	end else if (mem_stall_req_i) begin
		stall_sign	<= 7'b0111111;
	end else if (branch_stall_req_i) begin
		stall_sign	<= 7'b0001000;
	end else if (if_stall_req_i) begin
		stall_sign	<= 7'b0000100;
	end else begin
		stall_sign	<= 7'b0000000;
	end
end

endmodule // ctrl
