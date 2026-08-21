# Phase 2: 5-Stage Pipeline with Hazard Handling

## Summary

The single-cycle RV32I core (`cpu.v`, preserved untouched as a verified reference) has been re-implemented as a classic 5-stage pipeline (`cpu_pipeline.v`): IF → ID → EX → MEM → WB. All existing stage-local modules (ALU, register file, control unit, branch comparator, etc.) were reused unchanged — only the top-level wiring changed, with four new pipeline registers inserted between stages and two new hazard-handling units added.

## Architecture

- **IF**: PC, PC+4 adder, instruction memory
- **ID**: register file (read), immediate generator, control unit, field decode (rs1/rs2/rd/funct3/funct7)
- **EX**: ALU, branch comparator, branch/JALR target computation, forwarding muxes
- **MEM**: data memory
- **WB**: writeback mux (ALU result / memory data / PC+4 / U-type result)

Pipeline registers: `if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg` — each carries forward exactly the data and control signals the later stages need, using a consistent `_IF`/`_ID`/`_EX`/`_MEM`/`_WB` suffix convention to track which pipeline stage a signal belongs to.

## Hazards handled

**Load-use hazard (`hazard_unit.v`)**
Detects when the instruction in EX is a load whose destination register matches an rs1/rs2 needed by the instruction right behind it in ID. Since the loaded value doesn't exist until MEM completes, this case cannot be forwarded — it requires a one-cycle stall: freeze the PC and IF/ID register, and insert a bubble into ID/EX.

**RAW hazards via forwarding (`forwarding_unit.v` + `forward_mux.v`)**
For all other read-after-write hazards (a value computed by an earlier instruction, needed before it's been written back to the register file), values are forwarded directly from EX/MEM or MEM/WB into the EX stage's ALU/branch comparator inputs, bypassing the register file. EX/MEM (fresher) takes priority over MEM/WB when both would match.

**Same-cycle register file write/read**
A distinct case from both of the above: when a producer and consumer are exactly far enough apart that the producer's WB and the consumer's ID land in the same clock cycle, forwarding through EX arrives too late (the producer has already left the pipeline) and the register file's own combinational read would return stale data. Fixed with an internal bypass in `register_file.v`: if `reg_write` is active and the register being read matches the register being written this cycle, return the write data directly instead of the stored value.

**Control hazards (branches/jumps)**
Branches are resolved in EX (via `branch_comp`), meaning by the time a branch is known to be taken, two wrong-path instructions have already been fetched (one in IF, one in ID). Both `IF/ID` and `ID/EX` are flushed (zeroed) in the same cycle a taken branch/jump is detected, converting the wrong-path instructions into harmless bubbles before they can execute. JAL/JALR share this same flush path, since they're just the unconditional case of the same `PCSrc_EX != 2'b00` condition.

## Bugs found and fixed during verification

Verification surfaced several genuinely subtle bugs — each caught via cycle-by-cycle `$monitor` tracing rather than guessing:

1. **PC never froze during a stall.** The hazard unit correctly signaled a stall, and IF/ID correctly froze, but the PC itself kept incrementing every cycle regardless, fetching into empty instruction memory and corrupting the pipeline downstream. Fixed by adding a `stall` input to `pc.v` that holds the current PC value instead of advancing.

2. **A copy-paste error connected a forwarded value to an output port instead of an input port** in the `ex_mem_reg` instantiation (`.write_data_out(forwarded_b)` instead of `.write_data_in(forwarded_b)`). This caused two different drivers to fight over the same wire, producing `z` (undefined) on every store instruction's data path. Found by tracing `write_data_MEM` directly and noticing it was `z` even when `MemWrite_MEM` was asserted.

3. **The classic "producer-WB-meets-consumer-ID-in-the-same-cycle" hazard**, distinct from both the load-use stall and EX-stage forwarding cases above — required the register file bypass described above.

## Verification approach

Two dedicated pipeline-level tests, each with a self-checking testbench:
- **Load-use hazard test** — a load immediately followed by an instruction using the loaded register; confirms the stall fires, the pipeline doesn't get stuck, and the correct value is used once available.
- **Branch flush test** — a taken branch with "poison" instructions planted in the skipped path; confirms those instructions never execute (registers stay unwritten) and the correct branch target is reached.

Both use the same self-checking pattern as Phase 1 (`DUT.RF.registers[n]` checks with `!==`/`===` for uninitialized-safe comparison).

## Known limitations / follow-ups

- The full Phase 1 instruction suite (JAL, JALR, LUI/AUIPC, I-type ALU ops) has not yet been re-run end-to-end through the pipeline as a full regression pass — the two hazard-specific tests above are sufficient to validate Phase 2's core claims, but a full regression pass is worth doing before Phase 3 verification work begins in earnest.
- No branch prediction — branches always resolve in EX with a flush penalty (2-cycle bubble on every taken branch/jump). A predictor is planned as one of the Phase 4 standout features.

## Next: Phase 3 — comprehensive self-checking verification suite
