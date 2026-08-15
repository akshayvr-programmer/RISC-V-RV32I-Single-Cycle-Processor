module branch_comp (
    input  [31:0] rs1_data,
    input  [31:0] rs2_data,
    input  [2:0]  funct3,
    output reg    branch_taken
);
    wire signed [31:0] s_rs1 = rs1_data;
    wire signed [31:0] s_rs2 = rs2_data;

    always @(*) begin
        case (funct3)
            3'b000: branch_taken = (rs1_data == rs2_data);        // BEQ
            3'b001: branch_taken = (rs1_data != rs2_data);        // BNE
            3'b100: branch_taken = (s_rs1 < s_rs2);                // BLT
            3'b101: branch_taken = (s_rs1 >= s_rs2);               // BGE
            3'b110: branch_taken = (rs1_data < rs2_data);          // BLTU
            3'b111: branch_taken = (rs1_data >= rs2_data);         // BGEU
            default: branch_taken = 1'b0;
        endcase
    end
endmodule
