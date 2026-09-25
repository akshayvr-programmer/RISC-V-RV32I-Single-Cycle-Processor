`timescale 1ns/1ps

module test_sign_ext_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    defparam DUT.IM.HEXFILE = "programs/test_sign_ext.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #200;

        $display("x1 = %0d (expect -2048)", $signed(DUT.RF.registers[1]));
        $display("x3 = %0d (expect 1, SLTI at boundary)", $signed(DUT.RF.registers[3]));
        $display("x2 = %0d (expect -2047)", $signed(DUT.RF.registers[2]));
        $display("x6 = %0d (expect 42, negative-offset load/store)", $signed(DUT.RF.registers[6]));

        if ($signed(DUT.RF.registers[1]) == -2048 &&
            $signed(DUT.RF.registers[2]) == -2047 &&
            $signed(DUT.RF.registers[3]) == 1 &&
            $signed(DUT.RF.registers[6]) == 42)
            $display("\nSIGN EXTENSION TEST PASSED");
        else
            $display("\nSIGN EXTENSION TEST FAILED");

        $finish;
    end

endmodule