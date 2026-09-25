`timescale 1ns/1ps

module test_jalr_negative_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    defparam DUT.IM.HEXFILE = "programs/test_jalr_negative.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #150;

        $display("x1 = %0d (expect 8, return address)", DUT.RF.registers[1]);
        $display("x5 = %0d (expect NOT 999, poison skipped)", DUT.RF.registers[5]);
        $display("x6 = %0d (expect NOT 999, poison skipped)", DUT.RF.registers[6]);
        $display("x8 = %0d (expect 42, correct jump target)", DUT.RF.registers[8]);

        if (DUT.RF.registers[1] == 8 && DUT.RF.registers[5] !== 999 &&
            DUT.RF.registers[6] !== 999 && DUT.RF.registers[8] == 42)
            $display("\nJALR NEGATIVE OFFSET TEST PASSED");
        else
            $display("\nJALR NEGATIVE OFFSET TEST FAILED");

        $finish;
    end

endmodule
