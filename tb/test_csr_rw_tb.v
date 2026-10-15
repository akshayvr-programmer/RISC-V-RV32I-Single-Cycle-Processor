`timescale 1ns/1ps

module test_csr_rw_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );
    defparam DUT.IM.HEXFILE = "programs/test_csr_rw.hex";

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;
        #200;

        $display("x2 = %0d (expect 123, read back what we wrote)", DUT.RF.registers[2]);
        $display("x4 = %0d (expect 123, CSRRS returns the OLD value)", DUT.RF.registers[4]);
        $display("x5 = %0d (expect 127, CSRRC returns the OLD value)", DUT.RF.registers[5]);
        $display("x6 = %0d (expect 122, final value after set then clear)", DUT.RF.registers[6]);
        $display("mtvec = %0d (expect 122)", DUT.CSR.mtvec);

        if (DUT.RF.registers[2] === 123 && DUT.RF.registers[4] === 123 &&
            DUT.RF.registers[5] === 127 && DUT.RF.registers[6] === 122 &&
            DUT.CSR.mtvec === 122)
            $display("\nCSR READ/WRITE TEST PASSED");
        else
            $display("\nCSR READ/WRITE TEST FAILED");

        $finish;
    end

endmodule