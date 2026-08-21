module mem_wb_reg(
    input wire clk,
    input wire rst,

    input wire [31:0] alu_result_in,
    input wire [31:0] u_result_in,
    input wire [31:0] memory_data_in,
    input wire [31:0] pc_plus4_in,
    input wire [4:0]  rd_in,

    input wire RegWrite_in,
    input wire [1:0] ResultSrc_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] u_result_out,
    output reg [31:0] memory_data_out,
    output reg [31:0] pc_plus4_out,
    output reg [4:0]  rd_out,

    output reg RegWrite_out,
    output reg [1:0] ResultSrc_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        alu_result_out  <= 0;
        u_result_out    <= 0;
        memory_data_out <= 0;
        pc_plus4_out    <= 0;
        rd_out          <= 0;
        RegWrite_out    <= 0;
        ResultSrc_out   <= 0;
    end else begin
        alu_result_out  <= alu_result_in;
        u_result_out    <= u_result_in;
        memory_data_out <= memory_data_in;
        pc_plus4_out    <= pc_plus4_in;
        rd_out          <= rd_in;
        RegWrite_out    <= RegWrite_in;
        ResultSrc_out   <= ResultSrc_in;
    end
end

endmodule