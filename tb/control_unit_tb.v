`timescale 1ns/1ps

module control_unit_tb;

reg [6:0] opcode;

wire Branch;
wire MemRead;
wire MemtoReg;
wire [1:0] ALUOp;
wire MemWrite;
wire ALUSrc;
wire RegWrite;

control_unit dut(
    .opcode(opcode),
    .Branch(Branch),
    .MemRead(MemRead),
    .MemtoReg(MemtoReg),
    .ALUOp(ALUOp),
    .MemWrite(MemWrite),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite)
);

initial begin

    $dumpfile("control_unit.vcd");
    $dumpvars(0, control_unit_tb);

    $monitor("T=%0t opcode=%b | RegWrite=%b ALUSrc=%b MemRead=%b MemWrite=%b MemtoReg=%b Branch=%b ALUOp=%b",
              $time, opcode, RegWrite, ALUSrc,
              MemRead, MemWrite, MemtoReg,
              Branch, ALUOp);

    // R-Type
    opcode = 7'b0110011;
    #10;

    // I-Type
    opcode = 7'b0010011;
    #10;

    // Load
    opcode = 7'b0000011;
    #10;

    // Store
    opcode = 7'b0100011;
    #10;

    // Branch
    opcode = 7'b1100011;
    #10;

    // Invalid
    opcode = 7'b1111111;
    #10;

    $finish;

end

endmodule
