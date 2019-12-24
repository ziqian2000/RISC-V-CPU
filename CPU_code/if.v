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

	// branch
	input 	wire 					branch_enable_i,
	input 	wire[`InstAddrBus] 		branch_addr_i,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign,

	// to & from icache
	// (read)
	output 	reg[`InstAddrBus] 		raddr_o,
	input 	wire 					hit_i,
	input 	wire[31:0]				inst_i,
	// (write)
	output 	reg 					we_o,
	output 	reg[`InstAddrBus] 		waddr_o,
	output 	reg[31:0] 				wdata_o


);

reg[3:0] 		state;
reg[31:0] 		inst;
reg[`InstBus] 	pc;

integer i; // cycle counter
// 12302 for simpleloop
// 26856 for multiarray

assign pc_o = pc - 32'h4;

reg[3:0] avoid_data_hazard;


always @(posedge clk) begin

	// $display(i);
	i <= i+1;

	if (rst == `RstEnable) begin
		if_request 	<= 0;
		if_addr 	<= 0;
		pc  		<= 0;
		if_inst 	<= 0;
		inst 		<= 0;
		state 		<= 0;
		we_o 		<= 0;
		avoid_data_hazard <= 0;
		i 			<= 0;
	// end else if(stall_sign[0]) begin
	// 	STALL
	end else if(branch_enable_i) begin
		if(!stall_sign[0]) begin
			if_request 	<= 0;
			if_addr 	<= 0;
			pc 			<= branch_addr_i;
			if_inst 	<= 0;
			inst 		<= 0;
			state 		<= 0;
		end
	end	else begin

		case(state)
			4'b0000: begin // send the 1st address
				if(!stall_sign[1])  begin
					// if(avoid_data_hazard == 0) begin
						if_request <= 1'b1;
						if_addr <= pc;
						if_inst <= 0;
						
						raddr_o <= pc;
						we_o <= 0;

						if(stall_sign[0]) begin
							state <= 4'b0000;
						end else begin
							state <= 4'b0001;
						end

						// avoid_data_hazard <= 4'ha; // !!!

					// end else begin
					// 	avoid_data_hazard <= avoid_data_hazard - 1;
					// 	if_inst <= 0;
					// end
				end
			end
			4'b0001: begin // the 1st byte is being prepared, send the 2nd request
				if(hit_i) begin
					state <= 4'b0000;
					if_inst <= inst_i;
					pc <= pc + 31'h4;
				end else if(stall_sign[0]) begin
					state <= 4'b1000;
				end else begin
					state <= 4'b0010;
					if_addr <= pc + 31'h1;
					if_inst <= 0;
				end
			end
			4'b0010: begin // the 2nd byte is being prepared, send the 3rd request
				if(!stall_sign[0]) begin
					inst[7:0] <= mem_ctrl_data;
					state <= 4'b0011;
					if_addr <= pc + 31'h2;
				end else begin
					state <= 4'b1000;
				end
			end
			4'b0011: begin // the 3rd byte is being prepared, send the 4th request
				if(!stall_sign[0]) begin
					inst[15:8] <= mem_ctrl_data;
					state <= 4'b0100;
					if_addr <= pc + 31'h3;
				end else begin
					state <= 4'b1010;
				end
			end
			4'b0100: begin // the 4th byte is being prepared
				if(!stall_sign[0]) begin
					inst[23:16] <= mem_ctrl_data;
					state <= 4'b0101;
				end else begin
					state <= 4'b1100;
				end
			end
			4'b0101: begin // form the whole instr, send the next request
				if(!stall_sign[0]) begin
					// inst[31:24] <= mem_ctrl_data;
					if_inst <= {mem_ctrl_data, inst[23:0]};
					pc <= pc + 31'h4;
					// if_addr <= pc + 31'h4;

					state <= 4'b0000;

					we_o <= 1;
					waddr_o <= pc;
					wdata_o <= {mem_ctrl_data, inst[23:0]};
				end else begin
					state <= 4'b1110;
				end

			end

			// for interuption from MEM

			4'b1000: begin
				if(!stall_sign[0]) begin
					state <= 4'b1001;
					if_addr <= pc;
				end
			end
			4'b1001: begin
				state <= 4'b0010;
				if_addr <= pc + 31'h1;
			end

			4'b1010: begin
				if(!stall_sign[0]) begin
					state <= 4'b1011;
					if_addr <= pc + 31'h1;
				end
			end
			4'b1011: begin
				state <= 4'b0011;
				if_addr <= pc + 31'h2;
			end

			4'b1100: begin
				if(!stall_sign[0]) begin
					state <= 4'b1101;
					if_addr <= pc + 31'h2;
				end
			end
			4'b1101: begin
				state <= 4'b0100;
				if_addr <= pc + 31'h3;
			end

			4'b1110: begin
				if(!stall_sign[0]) begin
					state <= 4'b1111;
					if_addr <= pc + 31'h3;
				end
			end
			4'b1111: begin
				state <= 4'b0101;
			end

		endcase
	end
end	

endmodule