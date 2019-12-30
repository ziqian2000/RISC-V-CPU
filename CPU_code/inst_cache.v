module icache(
	input	wire 					clk,
	input 	wire 					rst,
	input 	wire 					rdy,

	// read
	input 	wire[`InstAddrBus]		raddr_i,
	output 	reg 					hit_o,
	output 	reg[31:0] 				inst_o,

	// write
	input 	wire 					we_i,
	input 	wire[`InstAddrBus] 		waddr_i,
	input 	wire[31:0] 				winst_i

);

wire[`CacheBlockNumLog2+1:2] 		raddr_idx;
wire[16:`CacheBlockNumLog2+2] 		raddr_tag;
wire[`CacheBlockNumLog2+1:2] 		waddr_idx;
wire[16:`CacheBlockNumLog2+2] 		waddr_tag;

(* ram_style = "registers" *) reg 								cache_valid[`CacheBlockNum-1:0];
(* ram_style = "registers" *) reg[14-`CacheBlockNumLog2:0]		cache_tag[`CacheBlockNum-1:0];
(* ram_style = "registers" *) reg[31:0] 						cache_data[`CacheBlockNum-1:0];

(* ram_style = "registers" *)reg 								victim_valid[`VictimCacheNum-1:0];
(* ram_style = "registers" *)reg[`InstAddrBus] 					victim_addr[`VictimCacheNum-1:0];
(* ram_style = "registers" *)reg[31:0] 							victim_data[`VictimCacheNum-1:0];

assign raddr_idx = raddr_i[`CacheBlockNumLog2+1:2];
assign raddr_tag = raddr_i[16:`CacheBlockNumLog2+2];
assign waddr_idx = waddr_i[`CacheBlockNumLog2+1:2];
assign waddr_tag = waddr_i[16:`CacheBlockNumLog2+2];

integer i;
integer j;

// write
always @(posedge clk) begin
	if (rst) begin
		for(i = 0; i < `CacheBlockNum; i = i + 1)
			cache_valid[i] 	<= 0;
		for(i = 0; i < `VictimCacheNum; i = i + 1)
			victim_valid[i] 	<= 0;
		j <= 0;
	end	else if(rdy) begin
		if(we_i) begin
			cache_valid[waddr_idx] <= 1;
			cache_tag[waddr_idx] <= waddr_tag;
			cache_data[waddr_idx] <= winst_i;

			victim_valid[j] <= 1;
			victim_data[j] <= cache_data[waddr_idx];
			victim_addr[j] 	<= {cache_tag[waddr_idx], waddr_idx};

			j <= (j == `VictimCacheNum-1 ? 0 : j + 1);
		end
	end
end

// read
always @(*) begin
	if(rst || !rdy)begin
		hit_o = 0;
		inst_o = 0;
	end else if(cache_tag[raddr_idx] == raddr_tag && cache_valid[raddr_idx]) begin
		hit_o = 1;
		inst_o = cache_data[raddr_idx];
	end else begin
		hit_o = 0;
		inst_o = 0;
		for(i = 0; i < `VictimCacheNum; i = i + 1)begin
			if(victim_valid[i] && victim_addr[i] == raddr_i[16:2]) begin
				hit_o = 1;
				inst_o = victim_data[i];
			end
		end
	end
end
endmodule