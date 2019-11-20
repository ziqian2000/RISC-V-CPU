module if_(
	input	wire					clk,
	input 	wire 					rst,

	// to & from mem_ctrl
	output	reg 					if_request, 	//	0 : no request 			
													//  1 : load instr for IF
	output 	reg[31:0]				if_addr,
	input	wire[7:0]				mem_ctrl_data,	// data from mem_ctrl
	input	wire[1:0]				if_or_mem_i,	// 01 : if 		10 : mem

	// to IF/ID
	output	reg[`InstAddrBus]		pc,
	output	reg[`InstBus]			if_inst
);

reg[3:0] state;
reg[31:0] inst;

always @(posedge clk) begin
		if (rst == `RstEnable) begin
			if_request <= 0;
			if_addr <= 0;
			pc <= 0;
			if_inst <= 0;
			inst <= 0;
			state <= 0;
		end 
		else begin 

			case(state)
				4'b0000: begin // send the 1st address
					if_request <= 1'b1;
					if_addr <= pc;
					if_inst <= 0;
					state <= 4'b0001;
				end
				4'b0001: begin // the 1st byte is being prepared, send the 2nd request
					state <= 4'b0010;
					if_addr <= pc + 31'h1;
					if_inst <= 0;
				end
				4'b0010: begin // the 2nd byte is being prepared, send the 3rd request
					inst[7:0] <= mem_ctrl_data;
					state <= 4'b0100;
					if_addr <= pc + 31'h2;
				end
				4'b0100: begin // the 3rd byte is being prepared, send the 4th request
					inst[15:8] <= mem_ctrl_data;
					state <= 4'b1000;
					if_addr <= pc + 31'h3;
				end
				4'b1000: begin // the 4th byte is being prepared
					inst[23:16] <= mem_ctrl_data;
					state <= 4'b1111;
				end
				4'b1111: begin // form the whole instr, send the next request
					inst[31:24] <= mem_ctrl_data;
					if_inst <= {mem_ctrl_data, inst[23:0]};
					pc <= pc + 31'h4;
					if_addr <= pc + 31'h4;
					state <= 4'b0001;
				end
			endcase
		end
	end	

endmodule