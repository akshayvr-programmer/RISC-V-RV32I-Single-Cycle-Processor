module register_file(
    input wire clk,
    input wire reg_write,

    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,

    input wire [31:0] write_data,

    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

reg [31:0] registers [0:31];

assign read_data1 = (rs1 == 0) ? 32'b0 :
                     (reg_write && rs1 == rd) ? write_data : registers[rs1];

assign read_data2 = (rs2 == 0) ? 32'b0 :
                     (reg_write && rs2 == rd) ? write_data : registers[rs2];

always @(posedge clk) begin
    if (reg_write && rd != 0)
        registers[rd] <= write_data;
end

endmodule
