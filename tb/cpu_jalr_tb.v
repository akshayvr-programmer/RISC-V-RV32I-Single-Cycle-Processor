`timescale 1ns/1ps

module cpu_jalr_tb;

    reg clk = 0;
    reg rst = 1;

    cpu DUT (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #150;

        $display("x1 = %0d (expect 8, return address)", DUT.RF.registers[1]);
        $display("x2 = %0d (expect 12, base register)", DUT.RF.registers[2]);
        $display("x5 = %0d (expect NOT 999, means it was skipped)", DUT.RF.registers[5]);
        $display("x6 = %0d (expect NOT 999, means it was skipped)", DUT.RF.registers[6]);
        $display("x8 = %0d (expect 42, means we reached the jump target)", DUT.RF.registers[8]);

        if (DUT.RF.registers[1] == 8 && DUT.RF.registers[2] == 12 &&
            DUT.RF.registers[5] !== 999 && DUT.RF.registers[6] !== 999 &&
            DUT.RF.registers[8] == 42)
            $display("\nALL JALR TESTS PASSED");
        else
            $display("\nJALR TEST FAILED");

        $finish;
    end

endmodule