`timescale 1ns/1ps

module pc_tb;

reg clk;
reg rst;
reg [31:0] next_pc;
wire [31:0] pc;

pc dut (
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc(pc)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("pc.vcd");
    $dumpvars(0, pc_tb);

    clk = 0;
    rst = 1;
    next_pc = 0;

    #10;
    rst = 0;

    next_pc = 32'd4;
    #10;

    next_pc = 32'd8;
    #10;

    next_pc = 32'd12;
    #10;

    $finish;
end

endmodule
