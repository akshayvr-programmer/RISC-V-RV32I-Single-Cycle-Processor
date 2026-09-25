`timescale 1ns/1ps

module test_branch_forward_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    defparam DUT.IM.HEXFILE = "programs/test_branch_forward.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #150;

        $display("x3 = %0d (expect 8)", DUT.RF.registers[3]);
        $display("x5 = %0d (expect NOT 999, poison must be skipped)", DUT.RF.registers[5]);
        $display("x6 = %0d (expect 42, correct branch target)", DUT.RF.registers[6]);

        if (DUT.RF.registers[3] == 8 && DUT.RF.registers[5] !== 999 && DUT.RF.registers[6] == 42)
            $display("\nBRANCH-ON-FORWARDED-VALUE TEST PASSED");
        else
            $display("\nBRANCH-ON-FORWARDED-VALUE TEST FAILED");

        $finish;
    end

endmodule
