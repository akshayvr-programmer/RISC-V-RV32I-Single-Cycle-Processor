`timescale 1ns/1ps

module test_x0_guard_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    defparam DUT.IM.HEXFILE = "programs/test_x0_guard.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #100;

        
        $display("x1 = %0d (expect 0, read of x0)", DUT.RF.registers[1]);
        $display("x2 = %0d (expect 99, confirms pipeline continued)", DUT.RF.registers[2]);

       if (DUT.RF.registers[1] == 0 && DUT.RF.registers[2] == 99)
           $display("\nX0 GUARD TEST PASSED");
       else
           $display("\nX0 GUARD TEST FAILED");

        $finish;
    end

endmodule
