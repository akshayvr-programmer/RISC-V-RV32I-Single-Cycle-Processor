`timescale 1ns/1ps

module alu_tb;

reg [31:0] a;
reg [31:0] b;
reg [3:0] alu_control;

wire [31:0] result;
wire zero;

alu dut(
    .a(a),
    .b(b),
    .alu_control(alu_control),
    .result(result),
    .zero(zero)
);

initial begin

    $dumpfile("alu.vcd");
    $dumpvars(0, alu_tb);
    $monitor("Time=%0t a=%0d b=%0d alu_control=%b result=%0d zero=%b",
          $time, a, b, alu_control, result, zero);
    

    // ADD
    a = 10;
    b = 20;
    alu_control = 4'b0000;
    #10;

    // SUB
    a = 30;
    b = 10;
    alu_control = 4'b0001;
    #10;

    // AND
    a = 32'hF0F0F0F0;
    b = 32'h0F0F0F0F;
    alu_control = 4'b0010;
    #10;

    // OR
    alu_control = 4'b0011;
    #10;

    // XOR
    alu_control = 4'b0100;
    #10;

    // SLT
    a = 5;
    b = 10;
    alu_control = 4'b0101;
    #10;

    // SLL
    a = 1;
    b = 3;
    alu_control = 4'b0110;
    #10;

    // SRL
    a = 16;
    b = 2;
    alu_control = 4'b0111;
    #10;

    // Zero flag
    a = 5;
    b = 5;
    alu_control = 4'b0001;
    #10;

    $finish;

end

endmodule
