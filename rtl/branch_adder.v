module branch_adder(

    input wire [31:0] pc,
    input wire [31:0] immediate,

    output wire [31:0] branch_target

);

assign branch_target = pc + immediate;

endmodule
