module control_unit(

    input wire [6:0] opcode,

    output reg Branch,
    output reg Jump,
    output reg MemRead,
    output reg [1:0] ResultSrc,
    output reg [1:0] ALUOp,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite,
    output reg Jalr


);

always @(*) begin

    // Default values
    Branch    = 0;
    Jump      = 0;
    MemRead   = 0;
    ResultSrc = 2'b00;
    ALUOp     = 2'b00;
    MemWrite  = 0;
    ALUSrc    = 0;
    RegWrite  = 0;
    Jalr = 0;


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
            RegWrite  = 1;
            ALUSrc    = 1;
            MemRead   = 1;
            ResultSrc = 2'b01;
            ALUOp     = 2'b00;
        end

        // Store (SW)
        7'b0100011: begin
            ALUSrc   = 1;
            MemWrite = 1;
            ALUOp    = 2'b00;
        end

        // Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
        7'b1100011: begin
            Branch = 1;
            ALUOp  = 2'b01;
        end

        // JAL
        7'b1101111: begin
            RegWrite  = 1;
            Jump      = 1;
            ResultSrc = 2'b10;
        end

        // JALR
        7'b1100111: begin
            RegWrite  = 1;
            Jalr      = 1;
            ALUSrc    = 1;
            ALUOp     = 2'b00;      // ADD, same as loads — rs1 + immediate
            ResultSrc = 2'b10;      // write PC+4 back, same as JAL
        end

        // LUI
        7'b0110111: begin
            RegWrite = 1;
            ResultSrc = 2'b11;
        end

        // AUIPC

        7'b0010111: begin
            RegWrite = 1;
            ResultSrc = 2'b11;
        end
        
        default: begin
            // Keep defaults
        end

    endcase

end

endmodule