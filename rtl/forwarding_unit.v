module forwarding_unit(
    input wire [4:0] rs1_EX,
    input wire [4:0] rs2_EX,

    input wire [4:0] rd_MEM,
    input wire       RegWrite_MEM,

    input wire [4:0] rd_WB,
    input wire       RegWrite_WB,

    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

always @(*) begin
    // Default: no forwarding needed, use the plain register file value
    ForwardA = 2'b00;
    ForwardB = 2'b00;

    // EX hazard: the instruction one stage ahead (in MEM) is about to write
    // the exact register EX needs right now. Highest priority since it's
    // the freshest available value.
    if (RegWrite_MEM && (rd_MEM != 5'b0) && (rd_MEM == rs1_EX))
        ForwardA = 2'b10;
    else if (RegWrite_WB && (rd_WB != 5'b0) && (rd_WB == rs1_EX))
        ForwardA = 2'b01;

    if (RegWrite_MEM && (rd_MEM != 5'b0) && (rd_MEM == rs2_EX))
        ForwardB = 2'b10;
    else if (RegWrite_WB && (rd_WB != 5'b0) && (rd_WB == rs2_EX))
        ForwardB = 2'b01;
end

endmodule
