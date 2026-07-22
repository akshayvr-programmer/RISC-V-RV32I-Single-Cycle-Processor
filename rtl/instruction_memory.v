module instruction_memory(
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

reg [31:0] memory [0:255];

initial begin
    $readmemh("programs/test.hex", memory);
end

assign instruction = memory[addr[31:2]];

endmodule

