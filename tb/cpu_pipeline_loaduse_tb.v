`timescale 1ns/1ps

module cpu_pipeline_loaduse_tb;

    reg clk = 0;
    reg rst = 1;

    cpu_pipeline DUT (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        #10 rst = 0;

        $monitor("t=%0t pc=%0d instr_ID=%h alu_result_MEM=%0d MemWrite_MEM=%b write_data_MEM=%0d MemRead_MEM=%b memory_data_MEM=%0d wb_data=%0d",
          $time, DUT.pc_current, DUT.instruction_ID,
          DUT.alu_result_MEM, DUT.MemWrite_MEM, DUT.write_data_MEM,
          DUT.MemRead_MEM, DUT.memory_data_MEM, DUT.write_back_data_WB);
          

        #250;

        $display("x3 = %0d (expect 55, the loaded value)", DUT.RF.registers[3]);
        $display("x4 = %0d (expect 110, load-use dependent add)", DUT.RF.registers[4]);
        $display("x5 = %0d (expect 42, confirms pipeline didn't get stuck)", DUT.RF.registers[5]);

        if (DUT.RF.registers[3] == 55 && DUT.RF.registers[4] == 110 && DUT.RF.registers[5] == 42)
            $display("\nLOAD-USE STALL TEST PASSED");
        else
            $display("\nLOAD-USE STALL TEST FAILED");

        $finish;
    end

endmodule