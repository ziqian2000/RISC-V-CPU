// only need to pass instaddr and inst from if to id
module if_id(
    input wire                  clk,
    input wire                  rst,

    // from ctrl
    input wire[`StallBus]       stall_sign,
    // from if
    input wire[`InstAddrBus]    if_pc,
    input wire[`InstBus]        if_inst,

    // to id
    output reg[`InstAddrBus]    id_pc,
    output reg[`InstBus]        id_inst
);

    always @(posedge clk) begin
        if (rst) begin
            id_pc       <= `ZeroWord;
            id_inst     <= `ZeroWord;
        end else if (!stall_sign[2]) begin
            id_pc       <= if_pc;
            id_inst     <= if_inst;
        end else if (!stall_sign[3] && stall_sign[2]) begin
            id_pc       <= `ZeroWord;
            id_inst     <= `ZeroWord;
        end
    end

endmodule // if_id
