`timescale 1ns/1ps

module data_memory_tb;

reg clk;
reg MemRead;
reg MemWrite;
reg [31:0] address;
reg [31:0] write_data;

wire [31:0] read_data;

data_memory dut(
    .clk(clk),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .address(address),
    .write_data(write_data),
    .read_data(read_data)
);

always #5 clk = ~clk;

initial begin

    $dumpfile("data_memory.vcd");
    $dumpvars(0, data_memory_tb);

    $monitor("T=%0t Addr=%0d MemRead=%b MemWrite=%b WriteData=%0d ReadData=%0d",
             $time, address, MemRead, MemWrite,
             write_data, read_data);

    clk = 0;

    //------------------------------------
    // Write 123 at address 8
    //------------------------------------

    MemRead = 0;
    MemWrite = 1;
    address = 8;
    write_data = 123;

    #10;

    //------------------------------------
    // Read address 8
    //------------------------------------

    MemWrite = 0;
    MemRead = 1;

    #10;

    //------------------------------------
    // Write 999 at address 16
    //------------------------------------

    MemRead = 0;
    MemWrite = 1;
    address = 16;
    write_data = 999;

    #10;

    //------------------------------------
    // Read address 16
    //------------------------------------

    MemWrite = 0;
    MemRead = 1;

    #10;

    $finish;

end

endmodule
