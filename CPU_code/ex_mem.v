module ex_mem(

    input wire                  clk,
    input wire                  rst,

    // ctrl signal
    input wire[`StallBus]       stall_sign,

    // read from ex
    input wire[`RegAddrBus]     ex_wd,
    input wire                  ex_wreg,
    input wire[`RegBus]         ex_wdata,
    input wire[`OpcodeBus]      ex_opcode,
    input wire[`FunctBus3]      ex_funct3,
    input wire[`InstAddrBus]    ex_mem_addr,

    // output to mem
    output reg[`RegAddrBus]     mem_wd,
    output reg                  mem_wreg,
    output reg[`RegBus]         mem_wdata,
    output reg[`OpcodeBus]      mem_opcode,
    output reg[`FunctBus3]      mem_funct3,
    output reg[`InstAddrBus]    mem_mem_addr
);

    always @ (posedge clk) begin
        if (rst) begin
            mem_wd          <= `NOPRegAddr;
            mem_wreg        <= `WriteDisable;
            mem_wdata       <= `ZeroWord;
            mem_opcode      <= `NON_OP;
            mem_funct3      <= `NON_FUNCT3;
            mem_mem_addr    <= `ZeroWord;
        end else if (stall_sign[4] && !stall_sign[5]) begin
            mem_wd          <= `NOPRegAddr;
            mem_wreg        <= `WriteDisable;
            mem_wdata       <= `ZeroWord;
            mem_opcode      <= `NON_OP;
            mem_funct3      <= `NON_FUNCT3;
            mem_mem_addr    <= `ZeroWord;
        end else if (!stall_sign[4]) begin
            mem_wd          <= ex_wd;
            mem_wreg        <= ex_wreg;
            mem_wdata       <= ex_wdata;
            mem_opcode      <= ex_opcode;
            mem_funct3      <= ex_funct3;
            mem_mem_addr    <= ex_mem_addr;
        end
    end

endmodule
