`timescale 1ns/1ps

module alu_control_tb;

reg [1:0] ALUOp;
reg [2:0] funct3;
reg [6:0] funct7;

wire [3:0] alu_control;

alu_control dut(
    .ALUOp(ALUOp),
    .funct3(funct3),
    .funct7(funct7),
    .alu_control(alu_control)
);

initial begin

    $dumpfile("alu_control.vcd");
    $dumpvars(0, alu_control_tb);

    $monitor("Time=%0t ALUOp=%b funct3=%b funct7=%b -> alu_control=%b",
              $time, ALUOp, funct3, funct7, alu_control);

    // Load/Store
    ALUOp = 2'b00;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    #10;

    // Branch
    ALUOp = 2'b01;
    #10;

    // ADD
    ALUOp = 2'b10;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    #10;

    // SUB
    funct7 = 7'b0100000;
    #10;

    // AND
    funct3 = 3'b111;
    funct7 = 7'b0000000;
    #10;

    // OR
    funct3 = 3'b110;
    #10;

    // XOR
    funct3 = 3'b100;
    #10;

    // SLT
    funct3 = 3'b010;
    #10;

    // SLL
    funct3 = 3'b001;
    #10;

    // SRL
    funct3 = 3'b101;
    #10;

    $finish;

end

endmodule
