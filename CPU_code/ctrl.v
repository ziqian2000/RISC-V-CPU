module ctrl (
    input wire                  rst,
    input wire                  rdy,

    input wire                  if_stall_req_i,
    input wire                  branch_stall_req_i,
    input wire                  mem_stall_req_i,
    output reg[`StallBus]       stall_sign
);

// wb mem ex id if mem_data if_data

always @ ( * ) begin
    if (rst) begin
        stall_sign  <= 7'b0000000;
    end else if (!rdy) begin
        stall_sign  <= 7'b1111100;
    end else if (mem_stall_req_i) begin
        stall_sign  <= 7'b0111111;
    end else if (branch_stall_req_i) begin
        stall_sign  <= 7'b0001000; // a bubble at id
    end else if (if_stall_req_i) begin
        stall_sign  <= 7'b0000100; // a bubble at if
    end else begin
        stall_sign  <= 7'b0000000;
    end
end

endmodule // ctrl
