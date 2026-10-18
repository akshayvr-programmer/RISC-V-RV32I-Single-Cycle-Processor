`timescale 1ns/1ps

module branch_predictor_tb;

    reg clk = 0;
    reg rst = 1;
    reg [31:0] pc_IF = 0;
    wire        predict_taken;
    wire [31:0] predict_target;

    reg         update_en = 0;
    reg [31:0]  update_pc = 0;
    reg         update_taken = 0;
    reg [31:0]  update_target = 0;

    branch_predictor DUT (
        .clk(clk), .rst(rst),
        .pc_IF(pc_IF),
        .predict_taken(predict_taken),
        .predict_target(predict_target),
        .update_en(update_en),
        .update_pc(update_pc),
        .update_taken(update_taken),
        .update_target(update_target)
    );

    always #5 clk = ~clk;

    integer errors = 0;

    // Tell the predictor what a branch really did
    task train(input [31:0] pc, input taken, input [31:0] tgt);
    begin
        @(negedge clk);
        update_en = 1; update_pc = pc; update_taken = taken; update_target = tgt;
        @(negedge clk);
        update_en = 0;
    end
    endtask

    // Check what the predictor says right now
    task check(input [8*40:1] name, input expected);
    begin
        #1;
        if (predict_taken !== expected) begin
            $display("FAIL: %0s (got %b, expected %b)", name, predict_taken, expected);
            errors = errors + 1;
        end else
            $display("PASS: %0s", name);
    end
    endtask

    initial begin
        #20 rst = 0;
        pc_IF = 32'h40;

        check("cold start predicts not taken", 0);

        train(32'h40, 1, 32'h80);
        check("after 1 taken, predicts taken", 1);
        if (predict_target !== 32'h80) begin
            $display("FAIL: target should be 0x80"); errors = errors + 1;
        end else $display("PASS: target remembered");

        train(32'h40, 1, 32'h80);          // counter now 3
        train(32'h40, 0, 32'h80);          // one outlier: counter 2
        check("one outlier does not flip it", 1);

        train(32'h40, 0, 32'h80);          // counter 1
        check("two not-takens flip it", 0);

        train(32'h40, 1, 32'h80);          // counter 2 again
        check("relearns taken", 1);

        pc_IF = 32'h440;                   // same page (index), different tag
        check("different PC, same page: ignored", 0);

        if (errors == 0) $display("\nBRANCH PREDICTOR TEST PASSED");
        else             $display("\nBRANCH PREDICTOR TEST FAILED (%0d errors)", errors);
        $finish;
    end

endmodule
