`timescale 1ns/1ps

module test_illegal_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );
    defparam DUT.IM.HEXFILE = "programs/test_illegal.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #200;

        $display("x8     = %0d (expect 42, handler ran)", DUT.RF.registers[8]);
        $display("x5     = %0d (expect NOT 999, flushed)", DUT.RF.registers[5]);
        $display("x6     = %0d (expect NOT 999, flushed)", DUT.RF.registers[6]);
        $display("mepc   = %0d (expect 8, address of the bad instruction)", DUT.CSR.mepc);
        $display("mcause = %0d (expect 2, illegal instruction)", DUT.CSR.mcause);

        if (DUT.RF.registers[8] === 42 &&
            DUT.RF.registers[5] !== 999 && DUT.RF.registers[6] !== 999 &&
            DUT.CSR.mepc === 8 && DUT.CSR.mcause === 2)
            $display("\nILLEGAL INSTRUCTION TEST PASSED");
        else
            $display("\nILLEGAL INSTRUCTION TEST FAILED");

        $finish;
    end

endmodule
