`timescale 1ns/1ps

module cpu_branch_tb;

    reg clk = 0;
    reg rst = 1;

    cpu DUT (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;

        // let it run enough cycles to execute all 10 instructions
        #200;

    $display("x5 = %0d (expect 0, means BNE branch was taken)", DUT.RF.registers[5]);
    $display("x6 = %0d (expect 0, means BLT branch was taken)", DUT.RF.registers[6]);
    $display("x7 = %0d (expect 0, means BGE branch was taken)", DUT.RF.registers[7]);
    $display("x8 = %0d (expect 42, means we reached the end correctly)", DUT.RF.registers[8]);

    if (DUT.RF.registers[5] !== 999 && DUT.RF.registers[6] !== 999 && DUT.RF.registers[7] !== 999 && DUT.RF.registers[8] == 42)
       $display("\nALL BRANCH TESTS PASSED");
    else
       $display("\nBRANCH TEST FAILED");

        $finish;
    end

endmodule
