`timescale 1ns/1ps

module bp_bench;
    parameter USE_BP = 1;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (.clk(clk), .rst(rst));

    defparam DUT.USE_BP = USE_BP;
    defparam DUT.IM.HEXFILE = "programs/bench_loop.hex";

    always #5 clk = ~clk;

    integer cycles = 0;
    always @(posedge clk) if (!rst) cycles <= cycles + 1;

    initial begin
        #10 rst = 0;
        wait (DUT.RF.registers[4] === 99);
        $display("USE_BP=%0d  cycles=%0d  x2=%0d (expect 50)",
                 USE_BP, cycles, DUT.RF.registers[2]);
        $finish;
    end

    initial begin
        #200000;
        $display("TIMEOUT");
        $finish;
    end
endmodule