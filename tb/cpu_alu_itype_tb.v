`timescale 1ns/1ps

module cpu_alu_itype_tb;

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

        $display("x1  = %0d (expect -5)",  $signed(DUT.RF.registers[1]));
        $display("x2  = %0d (expect 1, SLTI signed)",  $signed(DUT.RF.registers[2]));
        $display("x3  = %0d (expect 8, ANDI)",  $signed(DUT.RF.registers[3]));
        $display("x4  = %0d (expect -5, ORI)",  $signed(DUT.RF.registers[4]));

        $display("x5  = %0d (expect 4, XORI)",  $signed(DUT.RF.registers[5]));
        $display("x7  = %0d (expect 16, SLLI)", $signed(DUT.RF.registers[7]));
        $display("x9  = %0d (expect large positive, SRLI logical)", DUT.RF.registers[9]);
        $display("x10 = %0d (expect -1, SRAI arithmetic)", $signed(DUT.RF.registers[10]));

        if ($signed(DUT.RF.registers[1]) == -5 &&
            $signed(DUT.RF.registers[2]) == 1 &&
            $signed(DUT.RF.registers[3]) == 8 &&
            $signed(DUT.RF.registers[4]) == -5 &&
            $signed(DUT.RF.registers[5]) == 4 &&
            $signed(DUT.RF.registers[7]) == 16 &&
            $signed(DUT.RF.registers[10]) == -1)
            $display("\nALL ALU I-TYPE TESTS PASSED");
        else
            $display("\nALU I-TYPE TEST FAILED");

        $finish;
    end

endmodule