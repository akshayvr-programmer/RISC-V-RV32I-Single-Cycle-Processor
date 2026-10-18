`timescale 1ns/1ps

module test_bp_learn_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    always @(posedge clk)
    $display("t=%0t IFpc=%h predT=%b | EXpc=%h br=%b taken=%b guess=%b misp=%b | x1=%0d",
        $time, DUT.pc_current, DUT.pred_taken_IF,
        DUT.pc_out, DUT.Branch_out, DUT.branch_taken_EX,
        DUT.guess_taken_EX, DUT.mispredict_EX,
        $signed(DUT.RF.registers[1]));
        
    defparam DUT.IM.HEXFILE = "programs/test_bp_learn.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #250;

        $display("x1      = %0d (expect 0, loop counted down)", DUT.RF.registers[1]);
        $display("x2      = %0d (expect 42, loop finished)", DUT.RF.registers[2]);
        $display("valid   = %b   (expect 1, branch got an entry)", DUT.BP.valid[2]);
        $display("target  = %0d (expect 4, loop start)", DUT.BP.target[2]);
        $display("counter = %b  (expect 10: taken 4 times, not taken once)", DUT.BP.counter[2]);

        if (DUT.RF.registers[1] === 0 && DUT.RF.registers[2] === 42 &&
            DUT.BP.valid[2] === 1'b1 && DUT.BP.target[2] === 4 &&
            DUT.BP.counter[2] === 2'b10)
            $display("\nPREDICTOR LEARNING TEST PASSED");
        else
            $display("\nPREDICTOR LEARNING TEST FAILED");

        $finish;
    end

endmodule