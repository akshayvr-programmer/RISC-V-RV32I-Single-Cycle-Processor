`timescale 1ns/1ps

module tb_branch_comp;

    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    reg  [2:0]  funct3;
    wire        branch_taken;

    integer errors = 0;

    branch_comp DUT (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .branch_taken(branch_taken)
    );

    task check(input expected, input [63:0] test_name);
        begin
            #1; // let combinational logic settle
            if (branch_taken !== expected) begin
                $display("FAIL: %0s | rs1=%0d rs2=%0d funct3=%b -> got=%b expected=%b",
                          test_name, rs1_data, rs2_data, funct3, branch_taken, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        // BEQ (funct3 = 000)
        funct3 = 3'b000; rs1_data = 5; rs2_data = 5;
        check(1, "BEQ equal");
        rs1_data = 5; rs2_data = 6;
        check(0, "BEQ not equal");

        // BNE (funct3 = 001)
        funct3 = 3'b001; rs1_data = 5; rs2_data = 6;
        check(1, "BNE not equal");
        rs1_data = 5; rs2_data = 5;
        check(0, "BNE equal");

        // BLT (funct3 = 100) signed
        funct3 = 3'b100; rs1_data = -1; rs2_data = 1;
        check(1, "BLT -1 < 1");
        rs1_data = 1; rs2_data = -1;
        check(0, "BLT 1 < -1 false");

        // BGE (funct3 = 101) signed
        funct3 = 3'b101; rs1_data = 1; rs2_data = -1;
        check(1, "BGE 1 >= -1");
        rs1_data = -5; rs2_data = 1;
        check(0, "BGE -5 >= 1 false");

        // BLTU (funct3 = 110) unsigned
        funct3 = 3'b110; rs1_data = 32'hFFFFFFFF; rs2_data = 1; // huge unsigned vs 1
        check(0, "BLTU 0xFFFFFFFF < 1 false (unsigned)");
        rs1_data = 1; rs2_data = 32'hFFFFFFFF;
        check(1, "BLTU 1 < 0xFFFFFFFF true (unsigned)");

        // BGEU (funct3 = 111) unsigned
        funct3 = 3'b111; rs1_data = 32'hFFFFFFFF; rs2_data = 1;
        check(1, "BGEU 0xFFFFFFFF >= 1 (unsigned)");
        rs1_data = 1; rs2_data = 32'hFFFFFFFF;
        check(0, "BGEU 1 >= 0xFFFFFFFF false (unsigned)");

        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\n%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
