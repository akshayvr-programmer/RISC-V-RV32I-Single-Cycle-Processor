# RISC-V RV32I Processor in Verilog
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23465753.svg)](https://doi.org/10.5281/zenodo.23465753)

A **5-stage pipelined RV32I processor** implemented from scratch in **Verilog HDL**, built incrementally from a verified single-cycle reference core. Implements the complete RV32I base integer instruction set with hazard detection, forwarding, and control-hazard flushing, plus **CSR and trap support** (ECALL, MRET, illegal-instruction traps), a **dynamic branch predictor**, and a **synthesized and timing-closed FPGA build** for the Artix-7 (Basys 3 chip, not yet flashed to a board).
 
The original single-cycle core (`cpu.v`) is preserved unchanged as a verified reference implementation alongside the pipelined core (`cpu_pipeline.v`).
 
---
## Highlights
- **12.4% fewer cycles** with the branch predictor on a branch-heavy benchmark (755 vs 661 cycles, identical results)
- **Meets 100 MHz timing** on an Artix-7 `xc7a35tcpg236-1` with the Basys 3 pin map (+0.132 ns setup slack), using about 1,300 LUTs and 1,400 flip-flops, no block RAM or DSPs. A bitstream was generated but not flashed to a board
- Synchronous traps (ECALL, illegal instruction) with MRET, resolved in EX with the same flush mechanism as branches
- Full self-checking regression, run with one command (`.\run_all.ps1`)
---
## Features
- **5-stage pipelined datapath** (IF/ID/EX/MEM/WB) with 4 pipeline registers
- Hazard detection unit: load-use stalling
- Forwarding unit: EX/MEM and MEM/WB bypass paths for RAW hazards
- Register file same-cycle write/read bypass
- Control-hazard flush logic for mispredicted branches, jumps, traps and MRET
- **Dynamic branch predictor**: 16-entry direct-mapped table, tagged, 2-bit saturating counters, predicts branches and JAL in IF, verified and recovered in EX
- **CSR file** (mstatus, mtvec, mepc, mcause) with CSRRW / CSRRS / CSRRC
- **Trap support**: ECALL, illegal-instruction trap, MRET
- Complete RV32I Single-Cycle reference datapath (`cpu.v`), preserved and verified
- Modular Verilog Design, Harvard Architecture
- 32 x 32-bit Register File
- ALU with full Arithmetic, Logical, Shift, and Signed Comparison Operations
- Dedicated Branch Comparator (all 6 RV32I branch conditions)
- Priority next-PC select: trap or MRET, then JALR, then mispredict recovery, then predicted-taken fetch, then PC+4
- 4-way Writeback Select (ALU result / memory / PC+4 / U-type result)
- Immediate Generator (I/S/B/U/J-type)
- `USE_BP` parameter to switch the predictor off for with/without measurements
- Cycle-accurate Simulation using Icarus Verilog
- Vivado synthesis and implementation for the Basys 3's Artix-7
---
## Current Instruction Support - Full RV32I Base ISA plus Zicsr basics
 
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
### System and CSR
- CSRRW, CSRRS, CSRRC *(register-operand forms; immediate forms not implemented)*
- ECALL *(traps with mcause 11)*, MRET *(returns to mepc)*
- Illegal instruction *(traps with mcause 2)*
**Status: full RV32I base instruction set implemented, pipelined, and verified, including hazard/forwarding correctness, boundary edge cases, traps, and branch prediction.**
 
---
## Processor Architecture (Pipelined)
 
```
   IF                ID                 EX                  MEM              WB
+--------+       +----------+      +------------+       +----------+     +----------+
|  PC    |       | Register |      |  Forwarding|       |   Data   |     |Writeback |
|  PC+4  |------>|   File   |----->|    Unit    |------>|  Memory  |---->|   MUX    |
|  IMEM  |       | Control  |      |    ALU     |       |          |     |          |
|  Branch|       | Immediate|      | Branch Cmp |       +----------+     +----------+
|  Pred. |       |   Gen    |      | CSR File   |             |               |
+--------+       +----------+      | Branch/    |             |               |
     ^                 ^           | JALR Target|             |               |
     |                 |           +------------+             |               |
     |          Hazard Detection Unit     |                   |               |
     |          (load-use stall)          |                   |               |
     |                                    |                   |               |
     +--- flush / redirect / mispredict --+                   |               |
        (branch, jump, trap resolved in EX;                   |               |
         predictor updated from EX)                           v               v
                                                        MEM/WB forward   WB write-back
                                                        (RAW hazard)     (register file)
 
Pipeline registers: IF/ID -> ID/EX -> EX/MEM -> MEM/WB
The prediction (taken flag and target) travels with each instruction through IF/ID and ID/EX.
```
 
See `docs/PHASE1_NOTES.md` (ISA completion), `docs/PHASE2_NOTES.md` (pipeline and hazard handling, including bugs found), `docs/PHASE3_NOTES.md` (edge-case verification suite), `docs/PHASE4_CSR_NOTES.md` (CSRs and traps), `docs/PHASE4_PREDICTOR_NOTES.md` (branch predictor and measured speedup), and `docs/PHASE4_FPGA_NOTES.md` (FPGA synthesis and timing) for detailed design notes and debugging history.
 
---
## Results
 
### Branch predictor
 
Benchmark: `programs/bench_loop.hex`, 100 laps of a loop with two branches (one steady, one alternating taken and not taken). Cycles counted from reset until the final result is written back.
 
| Configuration | Cycles | Final result |
|---|---:|---|
| Predictor off (`USE_BP = 0`) | 755 | correct |
| Predictor on (`USE_BP = 1`) | 661 | correct |
| Saved | 94 (12.4%, 1.14x) | |
 
A correct prediction costs 0 extra cycles. A misprediction costs 2, the same as a taken branch did before there was a predictor. The alternating branch is a hard case for a 2-bit counter, so a loop with only a steady branch would show a larger gain.
 
### FPGA synthesis and timing
 
Vivado 2026.1, part `xc7a35tcpg236-1` (Artix-7, speed grade -1), 100 MHz clock constraint.
 
| Metric | Result |
|---|---|
| Slice LUTs | 1,338 of 20,800 (6.4%) |
| Slice registers | 1,392 of 41,600 (3.4%) |
| Block RAM / DSP | 0 / 0 |
| Worst setup slack | +0.132 ns (all constraints met) |
| Worst hold slack | +0.099 ns |
| Implied max frequency | about 101.3 MHz |

 
The critical path runs from the forwarding mux through the branch comparator to the mispredict/flush decision, and about 75% of it is routing delay (the flush signal fans out to well over 100 flip-flops). With default implementation settings the pinned design missed 100 MHz by 7 ps; the `Performance_ExplorePostRoutePhysOpt` strategy closed it. **A bitstream was generated, but the design was never flashed to a board.** The figures are for one benchmark program with a fixed instruction ROM, so they are a lower bound. See `docs/PHASE4_FPGA_NOTES.md` for the full report and caveats; raw reports are in `docs/fpga/`.
 
---
## Directory Structure
```
RISC-V-RV32I/
|
├── rtl/
│   ├── pc.v                  (supports stall input)
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
│   ├── branch_predictor.v    (16-entry tagged predictor, 2-bit counters)
│   ├── csr_file.v            (mstatus, mtvec, mepc, mcause)
│   ├── if_id_reg.v
│   ├── id_ex_reg.v
│   ├── ex_mem_reg.v
│   ├── mem_wb_reg.v
│   ├── hazard_unit.v
│   ├── forwarding_unit.v
│   ├── forward_mux.v
│   ├── cpu.v                 (single-cycle reference, preserved)
│   └── cpu_pipeline.v        (pipelined core, USE_BP parameter, debug_out port)
|
├── tb/
│   ├── cpu_tb.v
│   ├── branch_comp_tb.v
│   ├── branch_predictor_tb.v
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
│   ├── test_jalr_negative_tb.v
│   ├── test_csr_rw_tb.v
│   ├── test_ecall_tb.v
│   ├── test_mret_tb.v
│   ├── test_illegal_tb.v
│   ├── test_bp_learn_tb.v
│   ├── test_bp_alternate_tb.v
│   └── bp_bench.v            (cycle counter, run with and without the predictor)
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
│   ├── test_jalr_negative.hex
│   ├── test_csr_rw.hex
│   ├── test_ecall.hex
│   ├── test_mret.hex
│   ├── test_illegal.hex
│   ├── test_bp_learn.hex
│   ├── test_bp_alternate.hex
│   └── bench_loop.hex        (100-lap benchmark, also used for FPGA synthesis)
|
├── fpga/
│   ├── fpga_top.v            (synthesis wrapper)
│   │   
    └── cpu_timing.xdc        (100 MHz clock constraint and Basys 3 pin map)
|
├── docs/
│   ├── PHASE1_NOTES.md
│   ├── PHASE2_NOTES.md
│   ├── PHASE3_NOTES.md
│   ├── PHASE4_CSR_NOTES.md
│   ├── PHASE4_PREDICTOR_NOTES.md
│   ├── PHASE4_FPGA_NOTES.md
│   └── fpga/                 (raw Vivado utilization and timing reports)
|
├── run_all.ps1               (compiles and runs every testbench, prints PASS/FAIL)
├── LICENSE
├── CITATION.cff
└── README.md
```
 
---
## Run the Regression
 
From the repo root in PowerShell (requires Icarus Verilog on the PATH):
 
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\run_all.ps1
```
 
It compiles every testbench in `tb/` against `rtl/` and prints PASS/FAIL for each. The last line reports how many testbenches had problems (expected: 0).
 
To reproduce the predictor measurement:
 
```powershell
$rtl = (Get-ChildItem rtl\*.v | Where-Object Length -gt 0).FullName
iverilog "-Pbp_bench.USE_BP=1" -o run.out $rtl tb\bp_bench.v ; vvp run.out
iverilog "-Pbp_bench.USE_BP=0" -o run.out $rtl tb\bp_bench.v ; vvp run.out
```
 
---

To rebuild the FPGA design, create a Vivado project for `xc7a35tcpg236-1` with `rtl/*.v`, `fpga/fpga_top.v` and `fpga/cpu_timing.xdc`, set `fpga_top` as top, and point the instruction memory at the benchmark with the Tcl console (use your own path):

## Verification
 
Three-tier verification approach:
1. **Module-level testbench** - isolates new logic (e.g. `branch_comp`, `hazard_unit`, `branch_predictor`) against known input/output pairs.
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
 
### CSR and trap correctness
 
| Case | Result |
|------|-------:|
| CSRRW / CSRRS / CSRRC read-modify-write | Pass |
| ECALL traps to mtvec, younger instructions squashed, mepc and mcause saved | Pass |
| MRET returns to the instruction after the ECALL | Pass |
| Illegal instruction traps with mcause 2 | Pass |
 
### Branch predictor correctness
 
| Case | Result |
|------|-------:|
| Predictor unit test (cold start, learning, target memory, hysteresis, relearn, index aliasing) | Pass |
| 5-lap loop: predictor learns taken, final not-taken lap recovered | Pass |
| Alternating branch stress test (frequent mispredictions, final state exact) | Pass |
| Full regression with prediction enabled | Pass |
 
---
## Known Limitations
- Not verified against the official `riscv-tests` compliance suite (would require a full RISC-V GCC toolchain) - verified instead via a custom-built edge-case suite targeting known-risky boundary and combination cases. See `docs/PHASE3_NOTES.md` for scope and rationale.
- No automated assembler - test programs are hand-encoded to hex. This has already caused one transcription bug (a misplaced register field in a JALR test), caught via the same tracing methodology used for RTL bugs.
- Traps cover ECALL and illegal instructions only. No interrupts, `mtval`, EBREAK, misaligned-access traps, privilege modes other than Machine, or CSR immediate forms.
- The FPGA build was synthesized, timing-closed and a bitstream generated, but it was **not flashed to a board** (no hardware test). Utilization and timing are for one benchmark program with a fixed instruction ROM, which lets synthesis remove logic the program never uses, so they are a lower bound. Pins are mapped but I/O delays are not constrained, so only register-to-register timing was checked.
- The predictor is small (16 entries, direct-mapped) and does not predict JALR, so function returns still pay the full 2-cycle flush.
- The FPGA build was synthesized and timing-closed but **not flashed to a board** (no bitstream, no hardware test). Utilization and timing are for one benchmark program with a fixed instruction ROM, which lets synthesis remove logic the program never uses, so they are a lower bound. Only register-to-register timing was checked.
---
## Tools Used
- Verilog HDL
- Icarus Verilog
- GTKWave
- Vivado 2026.1 (synthesis and implementation)
- VS Code
---
## Roadmap
- [x] **Phase 1: Complete RV32I ISA** - branches, jumps, upper immediates, full I-type ALU ops
- [x] **Phase 2: 5-stage pipeline** - hazard detection, forwarding, control-hazard flush handling
- [x] **Phase 3: Edge-case verification suite** - x0 guard, chained forwarding, sign-extension bounds, shift bounds, branch-on-forward, JALR negative offset
- [x] **Phase 4: CSR/trap support, branch predictor, FPGA synthesis and timing** - hardware flash and demo pending a board
- [ ] **Phase 5:** Design-notes documentation comparing architecture to Sargantana (BSC RVA23 core)
- [ ] **Phase 6:** CLI to load, run, and inspect the processor interactively
---
## License
MIT, see `LICENSE`.
 
---
## Author
**Akshay V R**
B.Tech Electronics & Communication Engineering
Netaji Subhas University of Technology (NSUT)
 