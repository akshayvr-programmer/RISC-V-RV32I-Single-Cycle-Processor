`timescale 1ns/1ps

module test_shift_bounds_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    defparam DUT.IM.HEXFILE = "programs/test_shift_bounds.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #150;

        $display("x2 = %0d (expect 1, shift by 0)", DUT.RF.registers[2]);
        $display("x3 = %0d (expect -2147483648, shift by 31)", $signed(DUT.RF.registers[3]));
        $display("x4 = %0d (expect 1, SRLI zero-fill)", DUT.RF.registers[4]);
        $display("x5 = %0d (expect -1, SRAI sign-fill)", $signed(DUT.RF.registers[5]));

        if (DUT.RF.registers[2] == 1 &&
            $signed(DUT.RF.registers[3]) == -2147483648 &&
            DUT.RF.registers[4] == 1 &&
            $signed(DUT.RF.registers[5]) == -1)
            $display("\nSHIFT BOUNDARY TEST PASSED");
        else
            $display("\nSHIFT BOUNDARY TEST FAILED");

        $finish;
    end

endmodule
