module pc_mux(

    input wire [1:0] PCSrc,

    input wire [31:0] pc_plus4,
    input wire [31:0] branch_target,
    input wire [31:0] jalr_target,

    output reg [31:0] next_pc

);

always @(*) begin
    case(PCSrc)
        2'b00: next_pc = pc_plus4;
        2'b01: next_pc = branch_target;   // taken branch OR JAL
        2'b10: next_pc = jalr_target;      // JALR
        default: next_pc = pc_plus4;
    endcase
end

endmodule