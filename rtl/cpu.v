module cpu(

    input wire clk,
    input wire rst

);

// PC
wire [31:0] pc_current;
wire [31:0] next_pc;
wire [31:0] pc_plus4;
wire [31:0] branch_target;

// Instruction
wire [31:0] instruction;

// Register File
wire [31:0] read_data1;
wire [31:0] read_data2;
wire [31:0] write_back_data;

// Immediate
wire [31:0] immediate;
// U-type immediate result
wire [31:0] u_result;
wire is_auipc = (instruction[6:0] == 7'b0010111);

// ALU
wire [31:0] alu_input;
wire [31:0] alu_result;
wire zero;

// Memory
wire [31:0] memory_data;

// Control
wire Branch;
wire Jump;
wire MemRead;
wire [1:0] ResultSrc;
wire [1:0] ALUOp;
wire MemWrite;
wire ALUSrc;
wire RegWrite;
wire is_rtype = (instruction[6:0] == 7'b0110011);


// ALU Control
wire [3:0] alu_control;

// PC Select
wire [1:0] PCSrc;
wire [31:0] jalr_target;
// Branch comparator
wire branch_taken;

assign PCSrc = Jalr ? 2'b10 :
               (Jump | (Branch & branch_taken)) ? 2'b01 :
               2'b00;
assign jalr_target = {alu_result[31:1], 1'b0};
assign u_result = is_auipc ? (pc_current + immediate) : immediate;


//=========================
// Program Counter
//=========================

pc PC(

    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc(pc_current)

);

//=========================
// PC + 4
//=========================

pc_adder PC4(

    .pc(pc_current),
    .pc_plus4(pc_plus4)

);

//=========================
// Branch Adder
//=========================

branch_adder BA(

    .pc(pc_current),
    .immediate(immediate),
    .branch_target(branch_target)

);

//=========================
// PC MUX
//=========================

pc_mux PCMUX(

    .PCSrc(PCSrc),
    .pc_plus4(pc_plus4),
    .branch_target(branch_target),
    .jalr_target(jalr_target),
    .next_pc(next_pc)

);

//=========================
// Instruction Memory
//=========================

instruction_memory IM(

    .addr(pc_current),
    .instruction(instruction)

);

//=========================
// Immediate Generator
//=========================

immediate_generator IMM(

    .instruction(instruction),
    .immediate(immediate)

);

//=========================
// Control Unit
//=========================

control_unit CTRL(

    .opcode(instruction[6:0]),

    .Branch(Branch),
    .Jump(Jump),
    .Jalr(Jalr),
    .MemRead(MemRead),
    .ResultSrc(ResultSrc),
    .ALUOp(ALUOp),
    .MemWrite(MemWrite),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite)

);

register_file RF(

    .clk(clk),
    .reg_write(RegWrite),

    .rs1(instruction[19:15]),
    .rs2(instruction[24:20]),
    .rd(instruction[11:7]),

    .write_data(write_back_data),

    .read_data1(read_data1),
    .read_data2(read_data2)

);

alu_src_mux ALUSRC(

    .ALUSrc(ALUSrc),

    .register_data(read_data2),
    .immediate(immediate),

    .alu_input(alu_input)

);

alu_control ALUCTRL(

    .ALUOp(ALUOp),
    .funct3(instruction[14:12]),
    .funct7(instruction[31:25]),
    .is_rtype(is_rtype),

    .alu_control(alu_control)

);

alu ALU(

    .a(read_data1),
    .b(alu_input),
    .alu_control(alu_control),

    .result(alu_result),
    .zero(zero)

);

data_memory DM(

    .clk(clk),
    .MemRead(MemRead),
    .MemWrite(MemWrite),

    .address(alu_result),
    .write_data(read_data2),

    .read_data(memory_data)

);

writeback_mux WB(

    .ResultSrc(ResultSrc),

    .alu_result(alu_result),
    .memory_data(memory_data),
    .pc_plus4(pc_plus4),
    .u_result(u_result),

    .write_back_data(write_back_data)

);

//=========================
// Branch Comparator
//=========================

branch_comp BCOMP(

    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .funct3(instruction[14:12]),

    .branch_taken(branch_taken)

);

endmodule
