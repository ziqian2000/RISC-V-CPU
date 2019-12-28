module icache(
	input	wire 					clk,
	input 	wire 					rst,
	input 	wire 					rdy,

	// read
	input 	wire[`InstAddrBus]		raddr_i,
	output 	reg 					hit_o,
	output 	wire[31:0] 				inst_o,

	// write
	input 	wire 					we_i,
	input 	wire[`InstAddrBus] 		waddr_i,
	input 	wire[31:0] 				winst_i

);

wire[`CacheBlockNumLog2+1:2] 		raddr_idx;
wire[16:`CacheBlockNumLog2+2] 		raddr_tag;
wire[`CacheBlockNumLog2+1:2] 		waddr_idx;
wire[16:`CacheBlockNumLog2+2] 		waddr_tag;

reg 								cache_valid[`CacheBlockNum-1:0];
reg[14-`CacheBlockNumLog2:0]		cache_tag[`CacheBlockNum-1:0];
reg[31:0] 							cache_data[`CacheBlockNum-1:0];

assign raddr_idx = raddr_i[`CacheBlockNumLog2+1:2];
assign raddr_tag = raddr_i[16:`CacheBlockNumLog2+2];
assign waddr_idx = waddr_i[`CacheBlockNumLog2+1:2];
assign waddr_tag = waddr_i[16:`CacheBlockNumLog2+2];

integer i;

// write
always @(posedge clk) begin
	if (rst) begin
		for(i = 0; i < `CacheBlockNum; i = i + 1)
			cache_valid[i] <= 0;
	end	else begin
		if(we_i) begin
			cache_valid[waddr_idx] <= 1;
			cache_tag[waddr_idx] <= waddr_tag;
			cache_data[waddr_idx] <= winst_i;
		end
	end
end

assign inst_o = cache_data[raddr_idx];

// read
always @(*) begin
	if(rst || !rdy)begin
		hit_o = 0;
		// inst_o = 0;
	// end else if(we_i && raddr_i == waddr_i) begin
	// 	hit_o = 1;
	// 	inst_o = winst_i;
	end else begin
		hit_o = cache_tag[raddr_idx] == raddr_tag && cache_valid[raddr_idx];
		// inst_o = cache_data[raddr_idx];
	end
end
// always @(*) begin
// 	if(rst || !rdy)begin
// 		hit_o = 0;
// 		inst_o = 0;
// 	end else if(we_i && raddr_i == waddr_i) begin
// 		hit_o = 1;
// 		inst_o = winst_i;
// 	end else if(cache_tag[raddr_idx] == raddr_tag && cache_valid[raddr_idx]) begin
// 		hit_o = 1;
// 		inst_o = cache_data[raddr_idx];
// 	end else begin
// 		hit_o = 0;
// 		inst_o = 0;
// 	end
// end
endmodule