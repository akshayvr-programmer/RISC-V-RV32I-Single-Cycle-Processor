`timescale 1ns/1ps

module cpu_jal_tb;

    reg clk = 0;
    reg rst = 1;

    cpu DUT (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #100;

        $display("x1 = %0d (expect 4, return address)", DUT.RF.registers[1]);
        $display("x5 = %0d (expect NOT 999, means it was skipped)", DUT.RF.registers[5]);
        $display("x8 = %0d (expect 42, means we reached the jump target)", DUT.RF.registers[8]);

        if (DUT.RF.registers[1] == 4 && DUT.RF.registers[5] !== 999 && DUT.RF.registers[8] == 42)
            $display("\nALL JAL TESTS PASSED");
        else
            $display("\nJAL TEST FAILED");

        $finish;
    end

endmodule