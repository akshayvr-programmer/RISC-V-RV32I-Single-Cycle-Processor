`timescale 1ns/1ps

module test_mret_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );
    defparam DUT.IM.HEXFILE = "programs/test_mret.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #300;

        $display("x9     = %0d (expect 77, we returned and kept going)", DUT.RF.registers[9]);
        $display("x10    = %0d (expect 12, handler read mepc and added 4)", DUT.RF.registers[10]);
        $display("mepc   = %0d (expect 12)", DUT.CSR.mepc);
        $display("mcause = %0d (expect 11)", DUT.CSR.mcause);

        if (DUT.RF.registers[9] === 77 && DUT.RF.registers[10] === 12 &&
            DUT.CSR.mepc === 12 && DUT.CSR.mcause === 11)
            $display("\nMRET TEST PASSED");
        else
            $display("\nMRET TEST FAILED");

        $finish;
    end

endmodule