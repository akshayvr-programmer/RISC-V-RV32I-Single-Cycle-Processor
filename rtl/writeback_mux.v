module writeback_mux(

    input wire [1:0] ResultSrc,

    input wire [31:0] alu_result,
    input wire [31:0] memory_data,
    input wire [31:0] pc_plus4,
    input wire [31:0] u_result,

    output reg [31:0] write_back_data

);

always @(*) begin
    case(ResultSrc)
        2'b00: write_back_data = alu_result;
        2'b01: write_back_data = memory_data;
        2'b10: write_back_data = pc_plus4;
        2'b11: write_back_data = u_result;
    endcase
end

endmodule