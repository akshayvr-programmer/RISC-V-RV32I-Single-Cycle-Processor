`timescale 1ns/1ps

module test_chain_forward_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    defparam DUT.IM.HEXFILE = "programs/test_chain_forward.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #150;

        $display("x1 = %0d (expect 5)", DUT.RF.registers[1]);
        $display("x2 = %0d (expect 10)", DUT.RF.registers[2]);
        $display("x3 = %0d (expect 15)", DUT.RF.registers[3]);
        $display("x4 = %0d (expect 25)", DUT.RF.registers[4]);

        if (DUT.RF.registers[1] == 5 && DUT.RF.registers[2] == 10 &&
            DUT.RF.registers[3] == 15 && DUT.RF.registers[4] == 25)
            $display("\nCHAINED FORWARDING TEST PASSED");
        else
            $display("\nCHAINED FORWARDING TEST FAILED");

        $finish;
    end

endmodule
