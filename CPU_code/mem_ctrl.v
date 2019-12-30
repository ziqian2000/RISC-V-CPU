module mem_ctrl(

	input 	wire 				rst,
	input 	wire 				rdy,

	// IF
	input 	wire				if_request, 	//	0 : no request 		1 : load instruction for IF
	input 	wire[31:0]			if_addr,

	// MEM
	input 	wire[1:0]			mem_request, 	// 	00 : no request 01 : LOAD	10 : STORE
	input	wire[31:0]			mem_addr,

	// common
	input	wire[7:0]			cpu_data_i, 	// the data sent from CPU(MEM)
	output 	wire[7:0]			cpu_data_o,		// the data sent to CPU
	output	reg[1:0]			if_or_mem_o,	// 01 : if 		10 : mem

	// RAM
	input	wire[7:0]			ram_data_i,	// the data sent from RAM
	output	reg[7:0]			ram_data_o,	// the data sent to RAM
	output 	reg[31:0]			ram_addr_o,	// the addr sent to RAM
	output	reg 				ram_rw		// 0 : read		1 : write

);

	always @(*) begin
		if (rst == `RstEnable) begin
			if_or_mem_o = 0;
			ram_data_o = 0;
			ram_addr_o = 0;
			ram_rw = 0;
		end else begin
			if(mem_request == 2'b01) begin // to load for MEM
				if_or_mem_o = 2'b10;
				ram_data_o = 0;
				ram_addr_o = mem_addr;
				ram_rw = 0;
			end else if(mem_request == 2'b10) begin // to store for MEM
				if_or_mem_o = 2'b10;
				ram_data_o = cpu_data_i;
				ram_addr_o = mem_addr;
				ram_rw = 1;
			end else if(if_request == 1) begin // to load a byte for IF
				if_or_mem_o = 2'b01;
				ram_data_o = 0;
				ram_addr_o = if_addr;
				ram_rw = 0;
			end else begin // nothing happened
				if_or_mem_o = 0;
				ram_data_o = 0;
				ram_addr_o = 0;
				ram_rw = 0;
			end
		end
	end

	assign cpu_data_o = ram_data_i;

endmodule