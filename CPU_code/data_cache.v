`include "defines.v"
module dcache(
	input	wire 					clk,
	input 	wire 					rst,
	input 	wire 					rdy,

	// read
	input 	wire[`InstAddrBus]		raddr_i,
	input 	wire[1:0]				rbyte_i, // 00: 1 byte, 01: 2 byte, 10: 4 byte
	output 	reg 					hit_o,
	output 	reg[31:0] 				data_o,

	// write
	input 	wire 					we_i,
	input 	wire[1:0] 				wbyte_i, // 00: 1 byte, 01: 2 byte, 10: 4 byte
	input 	wire[`InstAddrBus] 		waddr_i,
	input 	wire[31:0] 				wdata_i

);

wire[`InstAddrBus] 			raddr_i1;
wire[`InstAddrBus] 			raddr_i2;
wire[`InstAddrBus] 			raddr_i3;

wire[`Cache2BlockNumLog2-1:0] 	raddr_idx0;
wire[16:`Cache2BlockNumLog2] 	raddr_tag0;
wire[`Cache2BlockNumLog2-1:0] 	raddr_idx1;
wire[16:`Cache2BlockNumLog2] 	raddr_tag1;
wire[`Cache2BlockNumLog2-1:0] 	raddr_idx2;
wire[16:`Cache2BlockNumLog2] 	raddr_tag2;
wire[`Cache2BlockNumLog2-1:0] 	raddr_idx3;
wire[16:`Cache2BlockNumLog2] 	raddr_tag3;

wire[`InstAddrBus] 			waddr_i1;
wire[`InstAddrBus] 			waddr_i2;
wire[`InstAddrBus] 			waddr_i3;

wire[`Cache2BlockNumLog2-1:0] 	waddr_idx0;
wire[16:`Cache2BlockNumLog2] 	waddr_tag0;
wire[`Cache2BlockNumLog2-1:0] 	waddr_idx1;
wire[16:`Cache2BlockNumLog2] 	waddr_tag1;
wire[`Cache2BlockNumLog2-1:0] 	waddr_idx2;
wire[16:`Cache2BlockNumLog2] 	waddr_tag2;
wire[`Cache2BlockNumLog2-1:0] 	waddr_idx3;
wire[16:`Cache2BlockNumLog2] 	waddr_tag3;

reg 							cache_valid[`Cache2BlockNum-1:0];
reg[16-`Cache2BlockNumLog2:0] 	cache_tag[`Cache2BlockNum-1:0];
reg[7:0]	 					cache_data[`Cache2BlockNum-1:0];

assign raddr_i1 = raddr_i + 31'h1;
assign raddr_i2 = raddr_i + 31'h2;
assign raddr_i3 = raddr_i + 31'h3;

assign raddr_idx0 = raddr_i[`Cache2BlockNumLog2-1:0];
assign raddr_tag0 = raddr_i[16:`Cache2BlockNumLog2];
assign raddr_idx1 = raddr_i1[`Cache2BlockNumLog2-1:0];
assign raddr_tag1 = raddr_i1[16:`Cache2BlockNumLog2];
assign raddr_idx2 = raddr_i2[`Cache2BlockNumLog2-1:0];
assign raddr_tag2 = raddr_i2[16:`Cache2BlockNumLog2];
assign raddr_idx3 = raddr_i3[`Cache2BlockNumLog2-1:0];
assign raddr_tag3 = raddr_i3[16:`Cache2BlockNumLog2];


assign waddr_i1 = waddr_i + 31'h1;
assign waddr_i2 = waddr_i + 31'h2;
assign waddr_i3 = waddr_i + 31'h3;

assign waddr_idx0 = waddr_i[`Cache2BlockNumLog2-1:0];
assign waddr_tag0 = waddr_i[16:`Cache2BlockNumLog2];
assign waddr_idx1 = waddr_i1[`Cache2BlockNumLog2-1:0];
assign waddr_tag1 = waddr_i1[16:`Cache2BlockNumLog2];
assign waddr_idx2 = waddr_i2[`Cache2BlockNumLog2-1:0];
assign waddr_tag2 = waddr_i2[16:`Cache2BlockNumLog2];
assign waddr_idx3 = waddr_i3[`Cache2BlockNumLog2-1:0];
assign waddr_tag3 = waddr_i3[16:`Cache2BlockNumLog2];

integer i;

// write
always @(posedge clk) begin
	if (rst || !rdy) begin
		for(i = 0; i < `Cache2BlockNum; i = i + 1)
			cache_valid[i] <= 0;
	end	else begin
		if(we_i) begin

			case(rbyte_i)
				2'b00: begin // 1 byte
					cache_valid[raddr_idx0] <= 1;
					cache_tag[waddr_idx0] <= waddr_tag0;
					cache_data[waddr_idx0] <= wdata_i[7:0];
				end
				2'b01: begin // 2 byte
					cache_valid[raddr_idx0] <= 1;
					cache_valid[raddr_idx1] <= 1;
					cache_tag[waddr_idx0] <= waddr_tag0;
					cache_tag[waddr_idx1] <= waddr_tag1;
					cache_data[waddr_idx0] <= wdata_i[7:0];
					cache_data[waddr_idx1] <= wdata_i[15:8];
				end
				2'b10: begin // 4 byte
					cache_valid[raddr_idx0] <= 1;
					cache_valid[raddr_idx1] <= 1;
					cache_valid[raddr_idx2] <= 1;
					cache_valid[raddr_idx3] <= 1;
					cache_tag[waddr_idx0] <= waddr_tag0;
					cache_tag[waddr_idx1] <= waddr_tag1;
					cache_tag[waddr_idx2] <= waddr_tag2;
					cache_tag[waddr_idx3] <= waddr_tag3;
					cache_data[waddr_idx0] <= wdata_i[7:0];
					cache_data[waddr_idx1] <= wdata_i[15:8];
					cache_data[waddr_idx2] <= wdata_i[23:16];
					cache_data[waddr_idx3] <= wdata_i[31:24];
				end
			endcase

		end
	end
end

// read
always @(*) begin
	if(rst || !rdy)begin
		hit_o = 0;
		data_o = 0;
	end else begin

		case(rbyte_i)
			2'b00: begin // 1 byte
				hit_o = cache_tag[raddr_idx0] == raddr_tag0 && cache_valid[raddr_idx0];
				data_o = {24'b0, cache_data[raddr_idx0]};
			end
			2'b01: begin // 2 byte
				hit_o = cache_tag[raddr_idx0] == raddr_tag0 && cache_valid[raddr_idx0]
					 && cache_tag[raddr_idx1] == raddr_tag1 && cache_valid[raddr_idx1];
				data_o = {16'b0, cache_data[raddr_idx1], cache_data[raddr_idx0]};
			end
			2'b10: begin // 4 byte
				hit_o = cache_tag[raddr_idx0] == raddr_tag0 && cache_valid[raddr_idx0]
					 && cache_tag[raddr_idx1] == raddr_tag1 && cache_valid[raddr_idx1]
					 && cache_tag[raddr_idx2] == raddr_tag2 && cache_valid[raddr_idx2]
					 && cache_tag[raddr_idx3] == raddr_tag3 && cache_valid[raddr_idx3];
				data_o = {cache_data[raddr_idx3], cache_data[raddr_idx2],
						  cache_data[raddr_idx1], cache_data[raddr_idx0]};
			end
		endcase
	end
end
endmodule