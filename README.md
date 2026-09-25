# RISC-V RV32I Processor in Verilog
A **5-stage pipelined RV32I processor** implemented from scratch in **Verilog HDL**, built incrementally from a verified single-cycle reference core. Implements the complete RV32I base integer instruction set with hazard detection, forwarding, and control-hazard flushing, and is being extended toward CSR/trap support, branch prediction, and a real FPGA hardware demo.

The original single-cycle core (`cpu.v`) is preserved unchanged as a verified reference implementation alongside the pipelined core (`cpu_pipeline.v`).

---
## Features
- **5-stage pipelined datapath** (IF/ID/EX/MEM/WB) with 4 pipeline registers
- Hazard detection unit — load-use stalling
- Forwarding unit — EX/MEM and MEM/WB bypass paths for RAW hazards
- Register file same-cycle write/read bypass
- Control-hazard flush logic for taken branches/jumps
- Complete RV32I Single-Cycle reference datapath (`cpu.v`), preserved and verified
- Modular Verilog Design, Harvard Architecture
- 32 x 32-bit Register File
- ALU with full Arithmetic, Logical, Shift, and Signed Comparison Operations
- Dedicated Branch Comparator (all 6 RV32I branch conditions)
- 3-way PC Select (sequential / branch-or-jump / JALR)
- 4-way Writeback Select (ALU result / memory / PC+4 / U-type result)
- Immediate Generator (I/S/B/U/J-type)
- Cycle-accurate Simulation using Icarus Verilog
- Three-tier verification: module-level, CPU-level, and targeted edge-case testbenches

---
## Current Instruction Support - Full RV32I Base ISA

### Arithmetic
- ADD, SUB, ADDI

### Logical
- AND, OR, XOR, ANDI, ORI, XORI

### Comparison
- SLT, SLTI *(signed comparison, verified at boundary values)*

### Shifts
- SLL, SRL, SRA, SLLI, SRLI, SRAI *(SRA sign-extends, verified against SRL zero-fill, including shift-amount boundaries 0 and 31)*

### Memory
- LW, SW *(including negative offsets)*

### Branches
- BEQ, BNE, BLT, BGE, BLTU, BGEU *(dedicated `branch_comp` module, all 6 conditions, verified against both clean and forwarded operands)*

### Jumps
- JAL, JALR *(return address via widened `ResultSrc`, JALR LSB-masked per spec, verified with both positive and negative offsets)*

### Upper Immediates
- LUI, AUIPC *(computed directly, bypassing ALU)*

**Status: full RV32I base instruction set implemented, pipelined, and verified - including hazard/forwarding correctness and boundary edge cases.**

---
## Processor Architecture (Pipelined)

```
   IF                ID                 EX                  MEM              WB
+--------+       +----------+      +------------+       +----------+     +----------+
|  PC    |       | Register |      |  Forwarding|       |   Data   |     |Writeback |
|  PC+4  |------>|   File   |----->|    Unit    |------>|  Memory  |---->|   MUX    |
|  IMEM  |       | Control  |      |    ALU     |       |          |     |          |
+--------+       | Immediate|      | Branch Cmp |       +----------+     +----------+
     ^           |   Gen    |      | Branch/    |             |               |
     |           +----------+      | JALR Target|             |               |
     |                 ^           +------------+             |               |
     |                 |                  |                   |               |
     |          Hazard Detection Unit     |                   |               |
     |          (load-use stall)          |                   |               |
     |                                    |                   |               |
     +------------- flush/PCSrc ----------+                   |               |
                (branch/jump resolved in EX)                  |               |
                                                                v               v
                                                        MEM/WB forward   WB write-back
                                                        (RAW hazard)     (register file)

Pipeline registers: IF/ID -> ID/EX -> EX/MEM -> MEM/WB
```

See `docs/PHASE1_NOTES.md` (ISA completion), `docs/PHASE2_NOTES.md` (pipeline + hazard handling, including bugs found), and `docs/PHASE3_NOTES.md` (edge-case verification suite) for detailed design notes and debugging history.

---
## Directory Structure
```
RISC-V-RV32I/
|
├── rtl/
│   ├── pc.v                  (now supports stall input)
│   ├── instruction_memory.v  (parameterized HEXFILE for test swapping)
│   ├── register_file.v       (same-cycle write/read bypass)
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
│   ├── if_id_reg.v
│   ├── id_ex_reg.v
│   ├── ex_mem_reg.v
│   ├── mem_wb_reg.v
│   ├── hazard_unit.v
│   ├── forwarding_unit.v
│   ├── forward_mux.v
│   ├── cpu.v                 (single-cycle reference, preserved)
│   └── cpu_pipeline.v        (pipelined core)
|
├── tb/
│   ├── cpu_tb.v
│   ├── branch_comp_tb.v
│   ├── cpu_branch_tb.v
│   ├── cpu_jal_tb.v
│   ├── cpu_jalr_tb.v
│   ├── cpu_alu_itype_tb.v
│   ├── cpu_pipeline_loaduse_tb.v
│   ├── cpu_pipeline_branch_tb.v
│   ├── test_x0_guard_tb.v
│   ├── test_chain_forward_tb.v
│   ├── test_sign_ext_tb.v
│   ├── test_shift_bounds_tb.v
│   ├── test_branch_forward_tb.v
│   └── test_jalr_negative_tb.v
|
├── programs/
│   ├── test.hex
│   ├── test_jal.hex
│   ├── test_jalr.hex
│   ├── test_alu_itype.hex
│   ├── test_loaduse.hex
│   ├── test_pipeline_branch.hex
│   ├── test_x0_guard.hex
│   ├── test_chain_forward.hex
│   ├── test_sign_ext.hex
│   ├── test_shift_bounds.hex
│   ├── test_branch_forward.hex
│   └── test_jalr_negative.hex
|
├── docs/
│   ├── PHASE1_NOTES.md
│   ├── PHASE2_NOTES.md
│   └── PHASE3_NOTES.md
|
└── README.md
```

---
## Verification

Three-tier verification approach:
1. **Module-level testbench** - isolates new logic (e.g. `branch_comp`, `hazard_unit`) against known input/output pairs.
2. **CPU-level testbench** - hand-assembled RV32I programs loaded via `$readmemh`, run through the full datapath, register file contents checked against expected values.
3. **Targeted edge-case testbench** (Phase 3) - boundary conditions and cross-feature combinations not covered by the above (sign-extension limits, shift boundaries, chained/forwarded hazards).

All comparisons use `!==`/`===` rather than `!=`/`==` to correctly handle uninitialized (`x`) register state.

### Core instruction correctness

| Instruction | Result |
|------------|-------:|
| `addi x1,x0,5` | Pass |
| `add x3,x1,x2` | Pass |
| `sub x4,x2,x1` | Pass |
| `and/or/xor` | Pass |
| `sw`/`lw` (incl. negative offsets) | Pass |
| `bne/blt/bge/bltu/bgeu` | Pass (all 6 branch conditions) |
| `jal` (return addr + unconditional jump) | Pass |
| `jalr` (register-relative, LSB masked, incl. negative offsets) | Pass |
| `slti` (signed comparison, incl. boundary) | Pass |
| `andi/ori/xori` | Pass |
| `slli/srli/srai` (incl. shift amounts 0 and 31) | Pass |

### Pipeline hazard correctness

| Hazard case | Result |
|------------|-------:|
| Load-use stall (PC/IF-ID freeze, bubble insertion) | Pass |
| RAW hazard, single pair, EX/MEM forwarding | Pass |
| RAW hazard, chained (3+ consecutive dependents) | Pass |
| Register file same-cycle write/read bypass | Pass |
| Control hazard flush (taken branch, poison instructions squashed) | Pass |
| Branch comparator fed by a forwarded (not clean) operand | Pass |
| x0 write-guard (through hazard/forwarding paths) | Pass |

---
## Known Limitations
- Not verified against the official `riscv-tests` compliance suite (would require a full RISC-V GCC toolchain) - verified instead via a custom-built edge-case suite targeting known-risky boundary and combination cases. See `docs/PHASE3_NOTES.md` for scope and rationale.
- No automated assembler - test programs are currently hand-encoded to hex. This has already caused one transcription bug (a misplaced register field in a JALR test), caught via the same tracing methodology used for RTL bugs.
- No branch prediction yet - every taken branch/jump costs a 2-cycle flush penalty. Planned for Phase 4.
- No CSR/trap/exception support yet. Planned for Phase 4.

---
## Tools Used
- Verilog HDL
- Icarus Verilog
- GTKWave
- VS Code

---
## Roadmap
- [x] **Phase 1: Complete RV32I ISA** - branches, jumps, upper immediates, full I-type ALU ops
- [x] **Phase 2: 5-stage pipeline** - hazard detection, forwarding, control-hazard flush handling
- [x] **Phase 3: Edge-case verification suite** - x0 guard, chained forwarding, sign-extension bounds, shift bounds, branch-on-forward, JALR negative offset
- [ ] **Phase 4:** CSR/trap support, branch predictor, FPGA synthesis + hardware demo
- [ ] **Phase 5:** Design-notes documentation comparing architecture to Sargantana (BSC RVA23 core)
- [ ] **Phase 6:** CLI to load, run, and inspect the processor interactively

---
## Author
**Akshay V R**
B.Tech Electronics & Communication Engineering
Netaji Subhas University of Technology (NSUT)
