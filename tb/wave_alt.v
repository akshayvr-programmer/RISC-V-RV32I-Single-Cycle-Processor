`timescale 1ns/1ps

module wave_alt;
    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (.clk(clk), .rst(rst));

    defparam DUT.IM.HEXFILE = "programs/test_bp_alternate.hex";

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave_alt.vcd");
        $dumpvars(0, DUT);
        #10 rst = 0;
        #1200;
        $finish;
    end
endmodule