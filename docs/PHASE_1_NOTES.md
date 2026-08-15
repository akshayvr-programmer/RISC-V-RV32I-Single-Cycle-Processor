# Phase 1: Full RV32I ISA Support
 
## Summary
 
The processor now implements the complete RV32I base integer instruction set (all 47 base instructions), up from an initial subset of ~9. All additions are verified at the module level and end-to-end at the CPU level via self-checking testbenches.
 
## What was added
 
**Branches (BEQ/BNE/BLT/BGE/BLTU/BGEU)**
Replaced the original zero-flag-only branch logic with a dedicated `branch_comp` module that evaluates all six RV32I branch conditions based on `funct3`, including proper signed vs. unsigned comparison for BLT/BGE vs. BLTU/BGEU.
 
**Jumps (JAL, JALR)**
- Widened the single-bit `MemtoReg` writeback select into a 2-bit `ResultSrc`, adding PC+4 as a third writeback source (needed for storing return addresses).
- Added a `Jump` control signal for unconditional PC redirects (JAL), and a separate `Jalr` signal for register-relative jumps.
- Extended `pc_mux` from a 2-way to a 3-way select (`pc_plus4` / `branch_target` / `jalr_target`).
- JALR's target is computed via the existing ALU (`rs1 + immediate`) with the LSB masked to 0, per spec.
**Upper immediates (LUI, AUIPC)**
- Added a 4th `ResultSrc` option for U-type results, computed directly in `cpu.v` (bypassing the ALU, since these instructions don't use two register operands).
- AUIPC computes `PC + immediate`; LUI passes the immediate through unchanged.
**I-type ALU instructions (SLTI, ANDI, ORI, XORI, SLLI, SRLI, SRAI)**
These reused existing `funct3` decoding paths already present in `alu_control`, but two latent bugs were found and fixed in the process:
1. **SLT/SLTI was comparing operands as unsigned**, which would misorder negative operands (`-1 < 1` evaluated incorrectly). Fixed with `$signed()` comparison.
2. **The ADD/SUB funct7 check could false-positive on I-type instructions** — for I-type instructions, bits `[31:25]` are part of the sign-extended immediate, not a real `funct7` field, and could coincidentally match the SUB pattern. Fixed by gating the check on a new `is_rtype` signal.
Also added the previously-missing **SRA** (arithmetic right shift), which sign-extends rather than zero-fills — required for SRAI and R-type SRA.
 
## Verification approach
 
Every addition follows the same two-tier verification pattern:
1. **Module-level testbench** — isolates the new logic (e.g. `branch_comp`) and checks it against known input/output pairs.
2. **CPU-level testbench** — hand-assembled RV32I programs loaded via `$readmemh`, run through the full datapath, with register file contents checked against expected values (`DUT.RF.registers[n]`) after execution.
All comparisons use Verilog's `!==`/`===` (not `!=`/`==`) to correctly handle uninitialized (`x`) register state, since the register file currently has no reset logic.
 
## Known limitation
 
The register file has no reset — registers power up as `x` (uninitialized) rather than 0. This didn't block verification (tests check specific expected values, not "not-x"), but is worth fixing before the pipeline stage, since uninitialized state is easier to debug in a single-cycle design than a pipelined one.
 
## Next: Phase 2 — 5-stage pipeline with hazard handling
 
 