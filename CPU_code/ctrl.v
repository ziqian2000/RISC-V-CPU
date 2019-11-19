// a central controller to control the whole process by stalling some stages if necessary

module ctrl(
	input 	wire 			id_ready,
	output	wire			stall_if
);

always @(*) begin
	if(!id_ready) begin
		stall_if = 1'b1;
	end else begin
		stall_if = 0;
	end
end


endmodule