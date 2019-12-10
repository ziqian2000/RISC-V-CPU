module if_(
	input wire				  clk,
	input wire				  rst,

	// to & from ctrl
	// (request)
	output reg				 	if_mem_req_o,
	output reg 					branch_stall_req_o,
	// (stall)
	input wire[`StallBus]	   	stall_sign,

	// to IF/ID
	output wire[`InstAddrBus]	pc_o,
	output reg[`InstBus]		if_inst,

	// branch
	input wire				  	branch_enable_i,
	input wire[`InstAddrBus]	branch_addr_i,

	// mem ctrl
	output reg[`InstAddrBus]	if_addr,
	output reg				 	mem_we_o,
	input wire[`MemDataBus]	 	mem_data_i,

	// to & from icache
	// (read)
	input wire[`InstAddrBus]	cache_inst_i,
	input wire				  	cache_hit_i,
	output reg[`InstAddrBus]	cache_raddr_o,
	// (write)
	output reg[`InstAddrBus]	cache_waddr_o,
	output reg				 	cache_we_o,
	output reg[`InstBus]		cache_winst_o

);

reg[3:0]			state;
reg[31:0] 			inst;
reg[`InstAddrBus] 	pc;

assign pc_o = pc;

always @ (posedge clk) begin
	if (rst) begin
		pc					<= 0;   
		state			   	<= 0;
		if_addr		  		<= 0;
		mem_we_o			<= 0;
		branch_stall_req_o  <= 0;
		if_mem_req_o		<= 0;
		pc					<= 0;
		if_inst			  	<= 0;
		cache_waddr_o	   	<= 0;
		cache_we_o		  	<= 0;
		cache_winst_o	   	<= 0;
		cache_raddr_o	   	<= 0;
	end else if(branch_enable_i && !stall_sign[2]) begin
		pc					<= branch_addr_i;
		cache_raddr_o	   	<= branch_addr_i;
		state			   	<= 0;
		if_inst			  	<= 0;
		if_addr		  		<= 0;
		if_mem_req_o		<= 0;
		branch_stall_req_o	<= 0;
	end else begin
		case (state)
			4'b0000: begin
				cache_we_o  <= 0;
				if (!stall_sign[2] && !stall_sign[3]) begin
					if_mem_req_o			<= 1'b1;
					if_addr		  		<= pc;
					cache_raddr_o	   		<= pc;
					state				 	<= 4'b0001;
				end
			end
			4'b0001: begin
				if (cache_hit_i) begin
					if (!stall_sign[1]) begin
						if_inst		  				<= cache_inst_i;
						if_mem_req_o				<= 0;
						state			 			<= 4'b0000;
						if (cache_inst_i[6]) begin
							branch_stall_req_o   	<= 1'b1;
						end else begin
							branch_stall_req_o   	<= 0;
							pc				 		<= pc[17:0] + 17'h4;
						end
					end
				end else begin
					if (stall_sign[1]) begin
						state		<= 4'b1000;
					end else begin
						if_addr	<= pc[17:0] + 17'h1;
						state		<= 4'b0010;
					end
				end
			end
			4'b0010: begin
				if_addr	  		<= pc[17:0] + 17'h2;
				inst[7:0]	 		<= mem_data_i;
				state			 	<= 4'b0011;
			end
			4'b0011: begin
				if (stall_sign[1]) begin
					state			<= 4'b1010;
				end else begin
					if_addr	  	<= pc[17:0] + 17'h3;
					inst[15:8]	 	<= mem_data_i;
					state			<= 4'b0100;
				end
			end
			4'b0100: begin
				if (stall_sign[1]) begin
					state			<= 4'b1100;
				end else begin
					inst[23:16]	 <= mem_data_i;
					state			<= 4'b0101;
				end
			end
			4'b0101: begin
				if_inst		  		<= {mem_data_i, inst[23:0]};
				cache_we_o	  		<= 1'b1;
				cache_winst_o   	<= {mem_data_i, inst[23:0]};
				cache_waddr_o   	<= cache_raddr_o;
				if_mem_req_o		<= 0;
				state			 	<= 4'b0000;
				if (inst[6]) begin
					branch_stall_req_o   <= 1'b1;
				end else begin
					branch_stall_req_o   <= 0;
					pc				 <= pc[17:0] + 17'h4;
				end
			end
			/******************************************************************/
			4'b1000: begin
				if (!stall_sign[1]) begin
					if_addr	  	<= pc[17:0];
					state			<= 4'b1001;
				end
			end
			4'b1001: begin
				if_addr		  	<= pc[17:0] + 17'h1;
				state				<= 4'b0010;
			end
			4'b1010: begin
				if (!stall_sign[1]) begin
					if_addr	  	<= pc[17:0] + 17'h1;
					state			<= 4'b1011;
				end
			end
			4'b1011: begin
				if_addr	  		<= pc[17:0] + 17'h2;
				state			 	<= 4'b0011;
			end
			4'b1100: begin
				if (!stall_sign[1]) begin
					if_addr	  	<= pc[17:0] + 17'h2;
					state			<= 4'b1101;
				end
			end
			4'b1101: begin
				if_addr	  		<= pc[17:0] + 17'h3;
				state			 	<= 4'b0100;
			end
			default: begin
			end
		endcase
	end
end

endmodule