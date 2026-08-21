module pc (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire [31:0] next_pc,
    output reg [31:0] pc
);

always @(posedge clk) begin
    if (rst)
        pc <= 32'b0;
    else if (!stall)
        pc <= next_pc;
    // if stall is high, hold current pc (do nothing — no assignment)
end

endmodule