module data_memory(

    input wire clk,
    input wire MemRead,
    input wire MemWrite,

    input wire [31:0] address,
    input wire [31:0] write_data,

    output reg [31:0] read_data

);

reg [31:0] memory [0:255];

always @(posedge clk) begin
    if (MemWrite)
        memory[address[31:2]] <= write_data;
end

always @(*) begin
    if (MemRead)
        read_data = memory[address[31:2]];
    else
        read_data = 32'b0;
end

endmodule
