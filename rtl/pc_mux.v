module pc_mux(

    input wire PCSrc,

    input wire [31:0] pc_plus4,
    input wire [31:0] branch_target,

    output wire [31:0] next_pc

);

assign next_pc =
    (PCSrc) ? branch_target : pc_plus4;

endmodule
