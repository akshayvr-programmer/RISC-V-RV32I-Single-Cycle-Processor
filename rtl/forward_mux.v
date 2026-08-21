module forward_mux(
    input wire [1:0]  Forward,

    input wire [31:0] reg_value,     // plain register file value (no hazard)
    input wire [31:0] mem_value,     // forwarded from MEM stage
    input wire [31:0] wb_value,      // forwarded from WB stage

    output reg [31:0] forwarded_value
);

always @(*) begin
    case(Forward)
        2'b00: forwarded_value = reg_value;
        2'b10: forwarded_value = mem_value;
        2'b01: forwarded_value = wb_value;
        default: forwarded_value = reg_value;
    endcase
end

endmodule
