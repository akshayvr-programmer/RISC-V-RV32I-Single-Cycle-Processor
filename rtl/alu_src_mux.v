module alu_src_mux(

    input wire ALUSrc,

    input wire [31:0] register_data,
    input wire [31:0] immediate,

    output wire [31:0] alu_input

);

assign alu_input = (ALUSrc) ? immediate : register_data;

endmodule
