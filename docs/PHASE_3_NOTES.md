# Phase 3: Edge-Case Verification Suite
 
## Summary
 
A targeted, custom-built suite of 6 tests, chosen specifically to exercise boundary conditions and interaction cases that Phase 1/2 testing hadn't yet covered — rather than the official `riscv-tests` compliance suite, which requires a full RISC-V GCC toolchain to build and was judged too large a lift for the return, given the pipeline had already been proven correct across its core mechanisms in Phase 2. All 6 tests pass against `cpu_pipeline`.
 
## Why these specific tests
 
Phase 1 and 2 testing proved the pipeline's *mechanisms* work — branches, jumps, forwarding, hazard stalling. But every test up to this point used "comfortable" values (small positive numbers, single hazard pairs). Real bugs tend to hide at boundaries and in combinations of features that individually work but haven't been tested *together*. This suite targets exactly those gaps.
 
## Tests and results
 
| Test | What it checks | Result |
|---|---|---|
| A — x0 write-guard | x0 stays zero even when an instruction tries to write it, and hazard/forwarding logic doesn't misfire treating x0 as a real destination | PASS |
| B — Chained forwarding | 3 consecutive dependent instructions (not just a single pair) — forwarding priority re-evaluates correctly every cycle as the "most recent producer" changes | PASS |
| C — Sign-extension boundaries | Most-negative 12-bit immediate (-2048), SLTI signed comparison at that boundary, negative LW/SW memory offset | PASS |
| D — Shift boundary values | Shift amount 0 (no-op) and shift amount 31 (max), confirming SRLI zero-fill vs. SRAI sign-fill hold at the extremes | PASS |
| E — Branch on forwarded value | branch_comp fed by a value forwarded from the immediately preceding instruction, not a clean register read | PASS |
| F — JALR with negative offset | Register-relative jump combined with a negative, sign-extended immediate | PASS (see bug below) |
 
## Bug found
 
**Test F initially failed** — but the root cause was in the hand-encoded test hex itself, not the RTL. The destination register (`rd`) field was placed in the wrong bit position within the 32-bit instruction word during manual encoding. Recomputing the encoding via the actual bit-shift formula (`(imm12<<20) | (rs1<<15) | (funct3<<12) | (rd<<7) | opcode`) rather than eyeballing it caught the error.
 
**Takeaway:** hand-encoding RISC-V instructions to hex is itself an error-prone process, independent of RTL correctness. This is a good argument for building or adopting a real assembler before Phase 4 testing scales further — a class of bug worth eliminating from the process rather than continuing to debug by hand each time.
 
## Verification approach
 
Same self-checking pattern as Phase 1/2: `DUT.RF.registers[n]` checks against expected values using `!==`/`===` for uninitialized-safe comparison, with `$monitor` tracing available for any failure (used for Test F's debug).
 
## Known limitations
 
- This is not the official `riscv-tests` compliance suite — it's a targeted custom suite covering specific gap areas identified after Phase 2. It increases confidence but isn't an industry-standard certification of correctness.
- No exhaustive coverage of every possible immediate/register value combination — the suite targets known-risky boundary cases (extremes, chained dependencies, cross-feature combinations) rather than exhaustive enumeration.
## Next: Phase 4 — CSR/traps, branch predictor, FPGA hardware demo
 
 