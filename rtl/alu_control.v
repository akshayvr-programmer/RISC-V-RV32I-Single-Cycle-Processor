module alu_control(

    input wire [1:0] ALUOp,
    input wire [2:0] funct3,
    input wire [6:0] funct7,

    output reg [3:0] alu_control

);

always @(*) begin

    case(ALUOp)

        // Load/Store
        2'b00:
            alu_control = 4'b0000;   // ADD

        // Branch
        2'b01:
            alu_control = 4'b0001;   // SUB

        // R-Type / I-Type
        2'b10: begin

            case(funct3)

                3'b000: begin
                    if(funct7 == 7'b0100000)
                        alu_control = 4'b0001;   // SUB
                    else
                        alu_control = 4'b0000;   // ADD / ADDI
                end

                3'b111:
                    alu_control = 4'b0010;       // AND

                3'b110:
                    alu_control = 4'b0011;       // OR

                3'b100:
                    alu_control = 4'b0100;       // XOR

                3'b010:
                    alu_control = 4'b0101;       // SLT

                3'b001:
                    alu_control = 4'b0110;       // SLL

                3'b101:
                    alu_control = 4'b0111;       // SRL

                default:
                    alu_control = 4'b0000;

            endcase

        end

        default:
            alu_control = 4'b0000;

    endcase

end

endmodule
