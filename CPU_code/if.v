module if_(
	input	wire					clk,
	input 	wire 					rst,

	// to & from pc_reg
	input	wire[`InstAddrBus]		pc,
	output	reg[`InstAddrBus]		pc_back_to_pc_reg,

	// to & from mem_ctrl
	output	reg 					if_request, 	//	0 : no request 			1 : load instruction for IF
	output 	reg[31:0]				if_addr,
	input	wire[31:0]				mcl_instr,		// instruction from mem_ctrl
	input	wire					busy_mem_ctrl,	// whether mem_ctrl is busy
	input	wire[1:0]				if_or_mem_i,	// 01 : if 		10 : mem
	input	wire[`InstAddrBus]		pc_back_from_mem_ctrl,

	// to IF/ID
	output	reg[`InstAddrBus]		if_pc,
	output	reg[`InstBus]			if_inst
);

always @(posedge clk) begin
		if (rst == `RstEnable) begin
			pc_back_to_pc_reg <= 0;
			if_request <= 0;
			if_addr <= 0;
			if_pc <= 0;
			if_inst <= 0;
		end 
		else begin 

			if(busy_mem_ctrl == 1'b1) begin 	// busy
				if_inst <= 0;
				if_addr <= 0;
			end else begin 				// not busy

				if(if_or_mem_i == 2'b01) begin 			// the data is sent to IF
					if_pc = pc;
					if_inst <= mcl_instr;
					pc_back_to_pc_reg = pc_back_from_mem_ctrl;

				end else if(if_or_mem_i == 2'b10) begin // the data is sent to MEM
					// just wait
				end

				if_request = 1'b1;
				if(if_or_mem_i == 2'b01) begin 	
					if_addr = pc_back_from_mem_ctrl;
				end else begin
					if_addr = pc;
				end

			end

		end
	end	

endmodule