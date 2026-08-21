module hazard_unit(
    input wire        MemRead_ID_EX,   // is the instruction currently in EX a load?
    input wire [4:0]  rd_ID_EX,        // its destination register
    input wire [4:0]  rs1_IF_ID,       // source registers of the instruction currently in ID
    input wire [4:0]  rs2_IF_ID,

    output wire stall
);

assign stall = MemRead_ID_EX &&
               (rd_ID_EX != 5'b0) &&
               ((rd_ID_EX == rs1_IF_ID) || (rd_ID_EX == rs2_IF_ID));

endmodule

