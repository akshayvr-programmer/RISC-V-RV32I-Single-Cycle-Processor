module cpu_pipeline(
    input wire clk,
    input wire rst
);

//=========================
// IF Stage
//=========================

wire [31:0] pc_current;
wire [31:0] next_pc;
wire [31:0] pc_plus4_IF;
wire [31:0] instruction_IF;

// These come from EX stage (declared later, wired here — Verilog allows this)
wire [1:0]  PCSrc_EX;
wire [31:0] branch_target_EX;
wire [31:0] jalr_target_EX;
wire        flush_IF_ID;   // control hazard flush, driven from EX stage
wire        stall_IF_ID;   // load-use hazard stall, driven from hazard unit (ID stage) - unused for now



pc PC(
    .clk(clk),
    .rst(rst),
    .stall(stall_hazard),
    .next_pc(next_pc),
    .pc(pc_current)
);

pc_adder PC4(
    .pc(pc_current),
    .pc_plus4(pc_plus4_IF)
);

pc_mux PCMUX(
    .PCSrc(PCSrc_EX),
    .pc_plus4(pc_plus4_IF),
    .branch_target(branch_target_EX),
    .jalr_target(jalr_target_EX),
    .next_pc(next_pc)
);

instruction_memory IM(
    .addr(pc_current),
    .instruction(instruction_IF)
);

//=========================
// IF/ID Pipeline Register
//=========================

wire [31:0] instruction_ID;
wire [31:0] pc_ID;
wire [31:0] pc_plus4_ID;

if_id_reg IFID(
    .clk(clk),
    .rst(rst),
    .stall(stall_IF_ID),
    .flush(flush_IF_ID),

    .instruction_in(instruction_IF),
    .pc_in(pc_current),
    .pc_plus4_in(pc_plus4_IF),

    .instruction_out(instruction_ID),
    .pc_out(pc_ID),
    .pc_plus4_out(pc_plus4_ID)
);

//=========================
// ID Stage
//=========================

wire [31:0] read_data1_ID;
wire [31:0] read_data2_ID;
wire [31:0] immediate_ID;

wire Branch_ID, Jump_ID, Jalr_ID, MemRead_ID, MemWrite_ID, ALUSrc_ID, RegWrite_ID;
wire [1:0] ResultSrc_ID, ALUOp_ID;

// Fields decoded directly from the instruction sitting in ID
wire [4:0] rs1_ID = instruction_ID[19:15];
wire [4:0] rs2_ID = instruction_ID[24:20];
wire [4:0] rd_ID  = instruction_ID[11:7];
wire [2:0] funct3_ID = instruction_ID[14:12];
wire [6:0] funct7_ID = instruction_ID[31:25];
wire is_rtype_ID = (instruction_ID[6:0] == 7'b0110011);
wire is_auipc_ID = (instruction_ID[6:0] == 7'b0010111);

// Looped back from WB stage (declared later)
wire        RegWrite_WB;
wire [4:0]  rd_WB;
wire [31:0] write_back_data_WB;

register_file RF(
    .clk(clk),
    .reg_write(RegWrite_WB),

    .rs1(rs1_ID),
    .rs2(rs2_ID),
    .rd(rd_WB),

    .write_data(write_back_data_WB),

    .read_data1(read_data1_ID),
    .read_data2(read_data2_ID)
);

immediate_generator IMM(
    .instruction(instruction_ID),
    .immediate(immediate_ID)
);

control_unit CTRL(
    .opcode(instruction_ID[6:0]),

    .Branch(Branch_ID),
    .Jump(Jump_ID),
    .Jalr(Jalr_ID),
    .MemRead(MemRead_ID),
    .ResultSrc(ResultSrc_ID),
    .ALUOp(ALUOp_ID),
    .MemWrite(MemWrite_ID),
    .ALUSrc(ALUSrc_ID),
    .RegWrite(RegWrite_ID)
);

//=========================
// ID/EX Pipeline Register
//=========================

wire [31:0] pc_out, pc_plus4_out, read_data1_out, read_data2_out, immediate_out;
wire [4:0]  rs1_out, rs2_out, rd_out;
wire [2:0]  funct3_out;
wire [6:0]  funct7_out;
wire        is_rtype_out, is_auipc_out;
wire        Branch_out, Jump_out, Jalr_out, MemRead_out, MemWrite_out, ALUSrc_out, RegWrite_out;
wire [1:0]  ResultSrc_out, ALUOp_out;

// Flush ID/EX on a taken branch/jump resolved in EX (declared below) —
// inserts a bubble so the wrong-path instruction currently in ID doesn't execute.
wire flush_ID_EX;

id_ex_reg IDEX(
    .clk(clk),
    .rst(rst),
    .flush(flush_ID_EX),

    .pc_in(pc_ID),
    .pc_plus4_in(pc_plus4_ID),
    .read_data1_in(read_data1_ID),
    .read_data2_in(read_data2_ID),
    .immediate_in(immediate_ID),
    .rs1_in(rs1_ID),
    .rs2_in(rs2_ID),
    .rd_in(rd_ID),
    .funct3_in(funct3_ID),
    .funct7_in(funct7_ID),
    .is_rtype_in(is_rtype_ID),
    .is_auipc_in(is_auipc_ID),

    .Branch_in(Branch_ID), .Jump_in(Jump_ID), .Jalr_in(Jalr_ID),
    .MemRead_in(MemRead_ID), .MemWrite_in(MemWrite_ID),
    .ALUSrc_in(ALUSrc_ID), .RegWrite_in(RegWrite_ID),
    .ResultSrc_in(ResultSrc_ID), .ALUOp_in(ALUOp_ID),

    .pc_out(pc_out), .pc_plus4_out(pc_plus4_out),
    .read_data1_out(read_data1_out), .read_data2_out(read_data2_out), .immediate_out(immediate_out),
    .rs1_out(rs1_out), .rs2_out(rs2_out), .rd_out(rd_out),
    .funct3_out(funct3_out), .funct7_out(funct7_out),
    .is_rtype_out(is_rtype_out), .is_auipc_out(is_auipc_out),

    .Branch_out(Branch_out), .Jump_out(Jump_out), .Jalr_out(Jalr_out),
    .MemRead_out(MemRead_out), .MemWrite_out(MemWrite_out),
    .ALUSrc_out(ALUSrc_out), .RegWrite_out(RegWrite_out),
    .ResultSrc_out(ResultSrc_out), .ALUOp_out(ALUOp_out)
);

wire stall_hazard;

hazard_unit HZ(
    .MemRead_ID_EX(MemRead_out),
    .rd_ID_EX(rd_out),
    .rs1_IF_ID(instruction_ID[19:15]),
    .rs2_IF_ID(instruction_ID[24:20]),

    .stall(stall_hazard)
);

assign stall_IF_ID = stall_hazard;
assign flush_ID_EX = flush_IF_ID | stall_hazard;


//=========================
// EX Stage
//=========================

wire [31:0] alu_input_EX;
wire [31:0] alu_result_EX;
wire        zero_EX;
wire [3:0]  alu_control_EX;
wire        branch_taken_EX;
wire [31:0] branch_target_calc_EX;
wire [31:0] u_result_EX;

// NOTE: no forwarding yet — read_data1_out/read_data2_out from ID/EX are used
// directly. This means back-to-back dependent instructions WILL currently
// produce wrong results. That's expected at this point — forwarding unit
// comes in a later step and this is exactly the bug it will fix.

alu_src_mux ALUSRC(
    .ALUSrc(ALUSrc_out),
    .register_data(forwarded_b),
    .immediate(immediate_out),
    .alu_input(alu_input_EX)
);

alu_control ALUCTRL(
    .ALUOp(ALUOp_out),
    .funct3(funct3_out),
    .funct7(funct7_out),
    .is_rtype(is_rtype_out),
    .alu_control(alu_control_EX)
);

alu ALU(
    .a(forwarded_a),
    
    .b(alu_input_EX),
    .alu_control(alu_control_EX),
    .result(alu_result_EX),
    .zero(zero_EX)
);

branch_comp BCOMP(
    .rs1_data(forwarded_a),
    .rs2_data(forwarded_b),
    .funct3(funct3_out),
    .branch_taken(branch_taken_EX)
);

branch_adder BA(
    .pc(pc_out),
    .immediate(immediate_out),
    .branch_target(branch_target_calc_EX)
);

assign branch_target_EX = branch_target_calc_EX;
assign jalr_target_EX   = {alu_result_EX[31:1], 1'b0};
assign u_result_EX      = is_auipc_out ? (pc_out + immediate_out) : immediate_out;

assign PCSrc_EX = Jalr_out ? 2'b10 :
                  (Jump_out | (Branch_out & branch_taken_EX)) ? 2'b01 :
                  2'b00;

// Flush IF/ID and ID/EX whenever EX resolves a taken branch/jump —
// the instructions fetched right after this one were fetched on the
// WRONG assumption (sequential PC) and must be squashed.
assign flush_IF_ID = (PCSrc_EX != 2'b00);

//=========================
// EX/MEM Pipeline Register
//=========================

wire [31:0] alu_result_MEM, u_result_MEM, write_data_MEM, pc_plus4_MEM;
wire [4:0]  rd_MEM;
wire        MemRead_MEM, MemWrite_MEM, RegWrite_MEM;
wire [1:0]  ResultSrc_MEM;

ex_mem_reg EXMEM(
    .clk(clk),
    .rst(rst),

    .alu_result_in(alu_result_EX),
    .u_result_in(u_result_EX),
    .write_data_in(forwarded_b),
    .pc_plus4_in(pc_plus4_out),
    .rd_in(rd_out),

    .MemRead_in(MemRead_out),
    .MemWrite_in(MemWrite_out),
    .RegWrite_in(RegWrite_out),
    .ResultSrc_in(ResultSrc_out),

    .alu_result_out(alu_result_MEM),
    .u_result_out(u_result_MEM),
    .write_data_out(write_data_MEM),
    .pc_plus4_out(pc_plus4_MEM),
    .rd_out(rd_MEM),

    .MemRead_out(MemRead_MEM),
    .MemWrite_out(MemWrite_MEM),
    .RegWrite_out(RegWrite_MEM),
    .ResultSrc_out(ResultSrc_MEM)
);

//=========================
// MEM Stage
//=========================

wire [31:0] memory_data_MEM;

data_memory DM(
    .clk(clk),
    .MemRead(MemRead_MEM),
    .MemWrite(MemWrite_MEM),

    .address(alu_result_MEM),
    .write_data(write_data_MEM),

    .read_data(memory_data_MEM)
);

//=========================
// MEM/WB Pipeline Register
//=========================

wire [31:0] alu_result_WB, u_result_WB, memory_data_WB, pc_plus4_WB;
wire [1:0] ResultSrc_WB;

wire [1:0] ForwardA, ForwardB;
wire [31:0] forwarded_a, forwarded_b;

forwarding_unit FWD(
    .rs1_EX(rs1_out),
    .rs2_EX(rs2_out),

    .rd_MEM(rd_MEM),
    .RegWrite_MEM(RegWrite_MEM),

    .rd_WB(rd_WB),
    .RegWrite_WB(RegWrite_WB),

    .ForwardA(ForwardA),
    .ForwardB(ForwardB)
);

forward_mux FMUXA(
    .Forward(ForwardA),
    .reg_value(read_data1_out),
    .mem_value(alu_result_MEM),
    .wb_value(write_back_data_WB),
    .forwarded_value(forwarded_a)
);

forward_mux FMUXB(
    .Forward(ForwardB),
    .reg_value(read_data2_out),
    .mem_value(alu_result_MEM),
    .wb_value(write_back_data_WB),
    .forwarded_value(forwarded_b)
);

mem_wb_reg MEMWB(
    .clk(clk),
    .rst(rst),

    .alu_result_in(alu_result_MEM),
    .u_result_in(u_result_MEM),
    .memory_data_in(memory_data_MEM),
    .pc_plus4_in(pc_plus4_MEM),
    .rd_in(rd_MEM),

    .RegWrite_in(RegWrite_MEM),
    .ResultSrc_in(ResultSrc_MEM),

    .alu_result_out(alu_result_WB),
    .u_result_out(u_result_WB),
    .memory_data_out(memory_data_WB),
    .pc_plus4_out(pc_plus4_WB),
    .rd_out(rd_WB),

    .RegWrite_out(RegWrite_WB),
    .ResultSrc_out(ResultSrc_WB)
);

//=========================
// WB Stage
//=========================

writeback_mux WB(
    .ResultSrc(ResultSrc_WB),

    .alu_result(alu_result_WB),
    .memory_data(memory_data_WB),
    .pc_plus4(pc_plus4_WB),
    .u_result(u_result_WB),

    .write_back_data(write_back_data_WB)
);

endmodule




