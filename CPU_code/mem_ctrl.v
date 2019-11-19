module mem_ctrl(

	input	wire 				clk,
	input 	wire 				rst,

	// IF
	input 	wire				if_request, 	//	0 : no request 			1 : load instruction for IF
	input 	wire[31:0]			if_addr,
	output	reg[`InstAddrBus]	pc_back,

	// MEM
	input 	wire[1:0]			mem_request, 	// 	00 : no request 		01 : LOAD 				10 : STORE
	input	wire[31:0]			mem_addr,

	// common
	input	wire[31:0]			cpu_data_i, 	// the data sent from CPU
	output 	reg[31:0]			cpu_data_o,		// the data sent to CPU
	output	reg[1:0]			if_or_mem_o,	// 01 : if 		10 : mem
	output	wire 				busy_o,

	// RAM
	input	wire[7:0]			ram_data_i,	// the data sent from RAM
	output	reg[7:0]			ram_data_o,	// the data sent to RAM
	output 	reg[31:0]			ram_addr_o,	// the addr sent to RAM
	output	reg 				ram_rw		// 0 : read		1 : write

);

	reg busy; // 0 : not busy		1 : busy
	reg hold; // hold on for 1 cycle so that the data can be read by CPU
	reg[2:0] remain_bytes; // bytes to read or write

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			cpu_data_o <= 0;
			if_or_mem_o <= 0;
			busy <= 0;
			hold <= 0;
			ram_data_o <= 0;
			ram_addr_o <= 0;
			ram_rw <= 0;
		end else begin
			if(hold) begin
				hold <= 0;
			end else begin
				if(busy == 0) begin // not busy
					if(if_request == 1) begin // to load instruction
						cpu_data_o <= 0;
						if_or_mem_o <= 2'b01;
						ram_addr_o <= if_addr;
						ram_rw <= 0;
						busy <= 1'b1;
						remain_bytes <= 3'b101; // 4 bytes to read
					end else if(mem_request == 2'b01) begin // to LOAD
						// TODO
					end else if(mem_request == 2'b10) begin // to STORE
						// TODO
					end else begin // nothing happened
						// TOOD
					end 

				end else begin // busy

					remain_bytes = remain_bytes - 1;
					ram_addr_o = ram_addr_o + 1'b1;

					if(ram_rw == 0) begin // read
					// make sure the following program run when new cpu_data_o is given
						cpu_data_o = cpu_data_o >> 8;
						cpu_data_o[31:31-7] = ram_data_i;
					end else begin // write
						// TODO
					end

					if(remain_bytes == 0) begin // done
						busy <= 0;
						hold <= 1'b1;
						pc_back <= if_addr + 3'b100;
					end
				end
			end
		end
	end

	assign busy_o = busy;


endmodule