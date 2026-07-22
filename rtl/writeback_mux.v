module writeback_mux(

    input wire MemtoReg,

    input wire [31:0] alu_result,
    input wire [31:0] memory_data,

    output wire [31:0] write_back_data

);

assign write_back_data =
    (MemtoReg) ? memory_data : alu_result;

endmodule
