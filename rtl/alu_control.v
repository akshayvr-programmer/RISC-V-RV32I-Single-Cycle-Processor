module alu_control(

    input wire [1:0] ALUOp,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire is_rtype,

    output reg [3:0] alu_control

);

always @(*) begin

    case(ALUOp)

        2'b00:
            alu_control = 4'b0000;   // ADD (load/store/JALR/AUIPC)

        2'b01:
            alu_control = 4'b0001;   // SUB (used internally, branches now use branch_comp)

        2'b10: begin

            case(funct3)

                3'b000: begin
                    if(is_rtype && funct7 == 7'b0100000)
                        alu_control = 4'b0001;   // SUB
                    else
                        alu_control = 4'b0000;   // ADD / ADDI
                end

                3'b111: alu_control = 4'b0010;   // AND / ANDI
                3'b110: alu_control = 4'b0011;   // OR / ORI
                3'b100: alu_control = 4'b0100;   // XOR / XORI
                3'b010: alu_control = 4'b0101;   // SLT / SLTI (signed)
                3'b001: alu_control = 4'b0110;   // SLL / SLLI

                3'b101: begin
                    if(funct7 == 7'b0100000)
                        alu_control = 4'b1000;   // SRA / SRAI
                    else
                        alu_control = 4'b0111;   // SRL / SRLI
                end

                default:
                    alu_control = 4'b0000;

            endcase

        end

        default:
            alu_control = 4'b0000;

    endcase

end

endmodule