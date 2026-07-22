`timescale 1ns/1ps

module cpu_tb;

reg clk;
reg rst;

cpu uut(
    .clk(clk),
    .rst(rst)
);

always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 1;

    #10;
    rst = 0;

    repeat (10) begin
        #10;

        $display("-------------------------------------------");
        $display("PC          = %h", uut.pc_current);
        $display("Instruction = %h", uut.instruction);
        $display("ALU Result  = %h", uut.alu_result);

        $display("x0 = %0d", uut.RF.registers[0]);
        $display("x1 = %0d", uut.RF.registers[1]);
        $display("x2 = %0d", uut.RF.registers[2]);
        $display("x3 = %0d", uut.RF.registers[3]);
        $display("x4 = %0d", uut.RF.registers[4]);
        $display("x5 = %0d", uut.RF.registers[5]);
        $display("x6 = %0d", uut.RF.registers[6]);
        $display("x7 = %0d", uut.RF.registers[7]);
        $display("x8 = %0d", uut.RF.registers[8]);
        $display("x9 = %0d", uut.RF.registers[9]);

        

    end

    $finish;

end

endmodule

