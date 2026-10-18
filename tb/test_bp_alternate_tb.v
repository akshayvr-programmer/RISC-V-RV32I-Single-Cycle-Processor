`timescale 1ns/1ps

module test_bp_alternate_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    defparam DUT.IM.HEXFILE = "programs/test_bp_alternate.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #1500;

        $display("x1 = %0d (expect 0, counter ran down)", $signed(DUT.RF.registers[1]));
        $display("x2 = %0d (expect 4, odd laps counted)", DUT.RF.registers[2]);
        $display("x4 = %0d (expect 99, loop finished)", DUT.RF.registers[4]);

        if (DUT.RF.registers[1] === 0 &&
            DUT.RF.registers[2] === 4 &&
            DUT.RF.registers[4] === 99)
            $display("\nALTERNATING BRANCH TEST PASSED");
        else
            $display("\nALTERNATING BRANCH TEST FAILED");

        $finish;
    end

endmodule
