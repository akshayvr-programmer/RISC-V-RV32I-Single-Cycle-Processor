module control_unit(

    input wire [6:0] opcode,

    output reg Branch,
    output reg MemRead,
    output reg MemtoReg,
    output reg [1:0] ALUOp,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite

);

always @(*) begin

    // Default values
    Branch   = 0;
    MemRead  = 0;
    MemtoReg = 0;
    ALUOp    = 2'b00;
    MemWrite = 0;
    ALUSrc   = 0;
    RegWrite = 0;

    case(opcode)

        // R-Type
        7'b0110011: begin
            RegWrite = 1;
            ALUSrc   = 0;
            ALUOp    = 2'b10;
        end

        // I-Type (ADDI, ANDI, ORI...)
        7'b0010011: begin
            RegWrite = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b10;
        end

        // Load (LW)
        7'b0000011: begin
            RegWrite = 1;
            ALUSrc   = 1;
            MemRead  = 1;
            MemtoReg = 1;
            ALUOp    = 2'b00;
        end

        // Store (SW)
        7'b0100011: begin
            ALUSrc   = 1;
            MemWrite = 1;
            ALUOp    = 2'b00;
        end

        // Branch (BEQ)
        7'b1100011: begin
            Branch = 1;
            ALUOp  = 2'b01;
        end

        default: begin
            // Keep defaults
        end

    endcase

end

endmodule
