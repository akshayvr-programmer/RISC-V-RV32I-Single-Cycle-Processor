module if_id_reg(
    input  wire clk,
    input  wire rst,
    input  wire stall,     // freeze this register (load-use hazard)
    input  wire flush,     // clear this register (branch/jump taken)

    input  wire [31:0] instruction_in,
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input wire pred_taken_in, input wire [31:0] pred_target_in,


    output reg  [31:0] instruction_out,
    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg pred_taken_out, output reg [31:0] pred_target_out

);

always @(posedge clk or posedge rst) begin
    if (rst || flush) begin
        instruction_out <= 32'b0;   // NOP
        pc_out           <= 32'b0;
        pc_plus4_out      <= 32'b0;
        pred_taken_out <= 1'b0;
        pred_target_out <= 32'b0;
    end else if (!stall) begin
        instruction_out <= instruction_in;
        pc_out           <= pc_in;
        pc_plus4_out      <= pc_plus4_in;
        pred_taken_out <= pred_taken_in;
        pred_target_out <= pred_target_in;
        
    end
    // if stall is high and not flushed, hold current values (do nothing)
end

endmodule