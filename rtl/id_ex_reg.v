module id_ex_reg(
    input wire clk,
    input wire rst,
    input wire flush,   // control hazard - squash this instruction into a bubble

    // Data
    input wire [31:0] pc_in,
    input wire [31:0] pc_plus4_in,
    input wire [31:0] read_data1_in,
    input wire [31:0] read_data2_in,
    input wire [31:0] immediate_in,
    input wire [4:0]  rs1_in,
    input wire [4:0]  rs2_in,
    input wire [4:0]  rd_in,
    input wire [2:0]  funct3_in,
    input wire [6:0]  funct7_in,
    input wire        is_rtype_in,
    input wire        is_auipc_in,

    // Control
    input wire Branch_in, Jump_in, Jalr_in, MemRead_in, MemWrite_in, ALUSrc_in, RegWrite_in,
    input wire [1:0] ResultSrc_in, ALUOp_in,

    // Outputs (same names, _out)
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] immediate_out,
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out,
    output reg [6:0]  funct7_out,
    output reg        is_rtype_out,
    output reg        is_auipc_out,

    output reg Branch_out, Jump_out, Jalr_out, MemRead_out, MemWrite_out, ALUSrc_out, RegWrite_out,
    output reg [1:0] ResultSrc_out, ALUOp_out
);

always @(posedge clk or posedge rst) begin
    if (rst || flush) begin
        pc_out <= 0; pc_plus4_out <= 0;
        read_data1_out <= 0; read_data2_out <= 0; immediate_out <= 0;
        rs1_out <= 0; rs2_out <= 0; rd_out <= 0;
        funct3_out <= 0; funct7_out <= 0;
        is_rtype_out <= 0; is_auipc_out <= 0;

        Branch_out <= 0; Jump_out <= 0; Jalr_out <= 0;
        MemRead_out <= 0; MemWrite_out <= 0; ALUSrc_out <= 0; RegWrite_out <= 0;
        ResultSrc_out <= 0; ALUOp_out <= 0;
    end else begin
        pc_out <= pc_in; pc_plus4_out <= pc_plus4_in;
        read_data1_out <= read_data1_in; read_data2_out <= read_data2_in; immediate_out <= immediate_in;
        rs1_out <= rs1_in; rs2_out <= rs2_in; rd_out <= rd_in;
        funct3_out <= funct3_in; funct7_out <= funct7_in;
        is_rtype_out <= is_rtype_in; is_auipc_out <= is_auipc_in;

        Branch_out <= Branch_in; Jump_out <= Jump_in; Jalr_out <= Jalr_in;
        MemRead_out <= MemRead_in; MemWrite_out <= MemWrite_in; ALUSrc_out <= ALUSrc_in; RegWrite_out <= RegWrite_in;
        ResultSrc_out <= ResultSrc_in; ALUOp_out <= ALUOp_in;
    end
end

endmodule
