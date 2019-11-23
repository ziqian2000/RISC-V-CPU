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
	output	wire[`InstAddrBus]		pc_o, 			// the true pc value by substract 4 from pc
	output	reg[`InstBus]			if_inst,

	// from ID
	input 	wire 					branch_enable_i,
	input 	wire[`InstAddrBus] 		branch_addr_i,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

reg[3:0] state;
reg[31:0] inst;
reg[`InstBus] pc;

assign pc_o = pc - 32'h4;

reg[3:0] avoid_data_h9zard;

always @(posedge clk) begin
		if (rst == `RstEnable) begin
			if_request 	<= 0;
			if_addr 	<= 0;
			pc  		<= 0;
			if_inst 	<= 0;
			inst 		<= 0;
			state 		<= 0;
			avoid_data_h9zard <= 4'h9;
		end else if(stall_sign[0]) begin
			// STALL
		end else if(branch_enable_i) begin
			if_request 	<= 0;
			if_addr 	<= 0;
			pc 			<= branch_addr_i;
			if_inst 	<= 0;
			inst 		<= 0;
			state 		<= 4'b0000;
		end	else begin 

			case(state)
				4'b0000: begin // send the 1st address
					if(avoid_data_h9zard == 0) begin
						if_request <= 1'b1;
						if_addr <= pc;
						if_inst <= 0;
						state <= 4'b0001;
						avoid_data_h9zard <= 4'h9;
					end else begin
						avoid_data_h9zard <= avoid_data_h9zard - 1;
						if_inst <= 0;
					end

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

					// state <= 4'b0001;
					state <= 4'b0000; // avoid data h9zrad

					//$display("read ins %x", {mem_ctrl_data, inst[23:0]});

				end
			endcase
		end
	end	

endmodule