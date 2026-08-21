# RISC-V Single-Cycle Processor (RV32I) in Verilog
A fully functional **RV32I Single-Cycle Processor** implemented from scratch in **Verilog HDL**. This project implements the complete RV32I base integer instruction set datapath and control logic, and is being extended toward a pipelined implementation with hazard handling and standout architectural features.

---
## Features
- Complete RV32I Single-Cycle Datapath
- Modular Verilog Design
- Harvard Architecture
- 32 × 32-bit Register File
- ALU with full Arithmetic, Logical, Shift, and Signed Comparison Operations
- Dedicated Branch Comparator (all 6 RV32I branch conditions)
- 3-way PC Select (sequential / branch-or-jump / JALR)
- 4-way Writeback Select (ALU result / memory / PC+4 / U-type result)
- Immediate Generator (I/S/B/U/J-type)
- Main Control Unit
- ALU Control Unit
- Instruction Memory
- Data Memory
- Load/Store Support
- Cycle-accurate Simulation using Icarus Verilog
- Two-tier verification: module-level + CPU-level self-checking testbenches

---
## Current Instruction Support — Full RV32I Base ISA

### Arithmetic
- ADD, SUB, ADDI

### Logical
- AND, OR, XOR, ANDI, ORI, XORI

### Comparison
- SLT, SLTI *(signed comparison, verified)*

### Shifts
- SLL, SRL, SRA, SLLI, SRLI, SRAI *(SRA sign-extends, verified against SRL zero-fill)*

### Memory
- LW, SW

### Branches
- BEQ, BNE, BLT, BGE, BLTU, BGEU *(dedicated `branch_comp` module, all 6 conditions)*

### Jumps
- JAL, JALR *(return address via widened `ResultSrc`, JALR LSB-masked per spec)*

### Upper Immediates
- LUI, AUIPC *(computed directly, bypassing ALU)*

**Status: full RV32I base instruction set implemented and verified.**

---
## Processor Architecture
```
                 +----------------+
                 | Program Counter|
                 +--------+-------+
                          |
                          v
               +----------------------+
               | Instruction Memory   |
               +----------+-----------+
                          |
          +---------------+----------------+
          |                                |
          v                                v
   Control Unit                 Immediate Generator
          |                                |
          |                                |
          v                                |
    Register File -------------------------+
          |            |                   |
          |            v                   |
          |     Branch Comparator          |
          |     (BEQ/BNE/BLT/BGE/          |
          |      BLTU/BGEU)                |
          |                    |
          v                    v
               ALU Source MUX
                     |
                     v
                    ALU  <---- ALU Control (SLT signed, SRA arithmetic,
                     |          funct7 gated by is_rtype)
          +----------+-----------+
          |                      |
          v                      |
      Data Memory                |
          |                      |
          +----------+-----------+
                     |
                     v
          Write Back MUX (4-way:
          ALU / Mem / PC+4 / U-type)
                     |
                     v
              Register File

  PC Select (3-way): pc+4 / branch_target / jalr_target
```

See `docs/PHASE1_NOTES.md` for detailed design notes, including two latent bugs found and fixed during I-type ALU verification (signed SLT comparison, funct7 false-positive on I-type immediates).

---
## Directory Structure
```
RISC-V-RV32I/
│
├── rtl/
│   ├── pc.v
│   ├── instruction_memory.v
│   ├── register_file.v
│   ├── immediate_generator.v
│   ├── control_unit.v
│   ├── alu_control.v
│   ├── alu.v
│   ├── data_memory.v
│   ├── alu_src_mux.v
│   ├── writeback_mux.v
│   ├── pc_adder.v
│   ├── branch_adder.v
│   ├── pc_mux.v
│   ├── branch_comp.v
│   └── cpu.v
│
├── tb/
│   ├── cpu_tb.v
│   ├── branch_comp_tb.v
│   ├── cpu_branch_tb.v
│   ├── cpu_jal_tb.v
│   ├── cpu_jalr_tb.v
│   └── cpu_alu_itype_tb.v
│
├── programs/
│   ├── test.hex
│   ├── test_jal.hex
│   ├── test_jalr.hex
│   └── test_alu_itype.hex
│
├── docs/
│   └── PHASE1_NOTES.md
│
└── README.md
```

---
## Verification
The processor is validated using simulation in **Icarus Verilog**, with a consistent two-tier approach for every new instruction:
1. **Module-level testbench** — isolates new logic (e.g. `branch_comp`) against known input/output pairs.
2. **CPU-level testbench** — hand-assembled RV32I programs loaded via `$readmemh`, run through the full datapath, register file contents checked against expected values.

All comparisons use `!==`/`===` rather than `!=`/`==` to correctly handle uninitialized (`x`) register state.

Example execution:

| Instruction | Result |
|------------|-------:|
| `addi x1,x0,5` | ✔ |
| `add x3,x1,x2` | ✔ |
| `sub x4,x2,x1` | ✔ |
| `and/or/xor` | ✔ |
| `sw`/`lw` | ✔ |
| `bne/blt/bge/bltu/bgeu` | ✔ (all 6 branch conditions, CPU-level) |
| `jal` (return addr + unconditional jump) | ✔ |
| `jalr` (register-relative jump, LSB masked) | ✔ |
| `slti` (signed comparison) | ✔ |
| `andi/ori/xori` | ✔ |
| `slli/srli/srai` (SRA sign-extension verified) | ✔ |

---
## Known Limitations
- Register file has no reset — registers power up as `x` (uninitialized) rather than 0. Flagged for fix before pipelining, where uninitialized state is harder to debug.
- No automated assembler — test programs are currently hand-encoded to hex.

---
## Tools Used
- Verilog HDL
- Icarus Verilog
- GTKWave
- VS Code

---
## Roadmap
- [x] **Phase 1: Complete RV32I ISA** — branches, jumps, upper immediates, full I-type ALU ops
- [x] **Phase 2:** 5-stage pipeline with hazard detection and forwarding
- [ ] **Phase 3:** Self-checking verification suite (riscv-tests or equivalent)
- [ ] **Phase 4:** CSR/trap support, branch predictor, FPGA synthesis + hardware demo
- [ ] **Phase 5:** Design-notes documentation comparing architecture to Sargantana (BSC RVA23 core)
- [ ] **Phase 6:** CLI to load, run, and inspect the processor interactively

---
## Author
**Akshay V R**
B.Tech Electronics & Communication Engineering
Netaji Subhas University of Technology (NSUT)
