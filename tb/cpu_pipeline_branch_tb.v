`timescale 1ns/1ps

module cpu_pipeline_branch_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;

        $monitor("t=%0t pc=%0d instr_IF=%h instr_ID=%h flush_IF_ID=%b PCSrc_EX=%b",
                  $time, DUT.pc_current, DUT.instruction_IF, DUT.instruction_ID,
                  DUT.flush_IF_ID, DUT.PCSrc_EX);

        #200;

        $display("x5 = %0d (expect NOT 999, poison must be flushed)", DUT.RF.registers[5]);
        $display("x6 = %0d (expect NOT 999, poison must be flushed)", DUT.RF.registers[6]);
        $display("x8 = %0d (expect 42, correct branch target reached)", DUT.RF.registers[8]);

        if (DUT.RF.registers[5] !== 999 && DUT.RF.registers[6] !== 999 && DUT.RF.registers[8] == 42)
            $display("\nBRANCH FLUSH TEST PASSED");
        else
            $display("\nBRANCH FLUSH TEST FAILED");

        $finish;
    end

endmodule
