# Phase 4B: Dynamic Branch Predictor

## Summary

A small dynamic branch predictor now sits in the IF stage. The first time a branch is seen it takes the normal 2-cycle flush; after that the predictor remembers it and fetch follows the prediction with no bubble. On a 100-lap benchmark with two branches it cuts the run from **755 to 661 cycles (12.4% fewer, 1.14x faster)** with identical results. All 29 testbenches pass.

## Design

A 16-entry direct-mapped table (`rtl/branch_predictor.v`):

| Field | Size | Purpose |
|---|---|---|
| index | `pc[5:2]` (4 bits) | Which entry the PC maps to |
| tag | `pc[31:6]` (26 bits) | Confirms the entry belongs to this exact PC |
| valid | 1 bit | Entry has been filled |
| target | 32 bits | Where the branch went when taken |
| counter | 2 bits | Saturating confidence: 00 strongly not taken, 01 weakly not taken, 10 weakly taken, 11 strongly taken |

- **Predict taken** when the entry hits (valid and tag match) and `counter[1]` is set.
- **Allocate** on the first resolution of a branch or JAL: counter starts at 10 if it was taken, 01 if not.
- **Update** when an entry exists: counter moves up or down by one (saturating); the target is refreshed only when the branch was taken.
- Reset clears every valid bit and starts every counter at 01.

The 2-bit counter means one odd outcome does not flip the prediction. A loop that exits once after many laps is still predicted taken on the next run.

**What is predicted:** conditional branches and JAL. **JALR is not predicted or recorded** because its target comes from a register and cannot be guessed from the PC; it resolves in EX with a flush, as before.

## How it fits in the pipeline

1. **IF:** the PC is looked up. If the predictor says taken, the next PC is the stored target instead of PC+4.
2. **IF/ID and ID/EX:** the prediction (`pred_taken`, `pred_target`) travels down the pipe beside the instruction.
3. **EX:** the real outcome is computed (`actual_taken`, `actual_target`). It is a mispredict when the instruction is a branch or JAL and either the direction differs from the guess, or both were taken but the targets differ.
4. **Recovery:** on a mispredict, flush the two younger instructions (the same flush signals as before) and redirect to `recover_pc = actual_taken ? actual_target : pc + 4`.
5. The predictor is updated from EX with the real outcome.

Next-PC priority: trap or MRET, then JALR, then mispredict recovery, then a predicted-taken fetch, then PC+4.

**Cost model:** a correct prediction costs 0 extra cycles. A mispredict costs 2 cycles, the same as a taken branch did before there was a predictor.

**On/off switch:** `cpu_pipeline` has a parameter `USE_BP` (default 1). Setting it to 0 gates the predictor's output to zero at the source, so IF and EX stay consistent. This is what makes a clean with and without measurement possible.

## Results

Benchmark: `programs/bench_loop.hex`, 100 laps of a loop with two branches. One is the steady backward loop branch. The other is an inner branch that alternates taken and not taken every lap (a hard case for a 2-bit counter). Cycles are counted from reset release until the final flag register is written back.

| Configuration | Cycles | Final result |
|---|---|---|
| `USE_BP = 0` (no predictor) | 755 | x2 = 50 (correct) |
| `USE_BP = 1` (predictor on) | 661 | x2 = 50 (correct) |
| Saved | 94 (12.4% fewer, 1.14x) | |

The gain is held back by the alternating branch, which the predictor gets wrong about half the time. A loop with only a steady backward branch would show a larger improvement, because nearly every lap would then be predicted correctly.

## Tests

| Test | What it checks | Result |
|---|---|---|
| branch_predictor_tb | Standalone unit test: cold start predicts not taken, learns taken, remembers target, one outlier does not flip it, two outliers do, relearns, ignores a different PC on the same index | PASS |
| test_bp_learn | 5-lap countdown: predictor learns the loop branch, and the final not-taken lap is caught and recovered (counter ends at 10) | PASS |
| test_bp_alternate | Alternating inner branch, forcing frequent mispredicts; final registers must still be exactly right | PASS |
| bp_bench | Cycle counter, run twice with `USE_BP` 1 and 0 | 661 vs 755 |
| Full regression | `.\run_all.ps1` across all 29 testbenches after turning prediction on | 0 problems |

## Bugs found along the way

- **The prediction bit was never copied through ID/EX.** The register zeroed `pred_taken_out` in reset but forgot to copy it in the normal branch, so EX always believed nobody had guessed. 28 of 29 tests still passed, because taken branches get flagged as mispredicts anyway and recover by luck. Only the one test with a predicted-taken branch that resolves not taken (`test_bp_learn`) exposed it. A cycle-by-cycle trace (`guess=0` on every lap while `predT=1` in IF) located it in minutes.
- **A refactor silently dropped the branch redirect.** Moving the branch logic into mispredict recovery left the PC mux without a path to the branch target, so branches flushed but never jumped. Caught by the existing branch tests.

**Takeaway:** a test that passes can still be passing for the wrong reason. The trace made the failure obvious where reading the code did not.

## Known limitations

- Direct-mapped: two branches 64 bytes apart share an index and evict each other (the tag prevents a wrong hit, but not the eviction).
- Only 16 entries, and a taken branch's first encounter is always a mispredict.
- JALR (including returns) is unpredicted. A return-address stack would be the natural next step.
- Measured on one hand-written benchmark, not on a standard suite.

## Reproduce

```
.\run_all.ps1
iverilog "-Pbp_bench.USE_BP=1" -o run.out $rtl tb\bp_bench.v ; vvp run.out
iverilog "-Pbp_bench.USE_BP=0" -o run.out $rtl tb\bp_bench.v ; vvp run.out
```

## Next

Part C: FPGA synthesis and timing for the Basys 3.
