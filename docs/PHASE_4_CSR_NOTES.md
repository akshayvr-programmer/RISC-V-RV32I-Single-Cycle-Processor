# Phase 4A: CSRs and Traps

## Summary

The pipeline now has a small Machine-mode CSR file and basic synchronous trap handling: `ECALL` and illegal instructions trap to a handler address held in `mtvec`, the faulting PC and cause are saved, and `MRET` returns. Everything resolves in the EX stage and reuses the same flush mechanism that branches already used, so no new kind of hazard logic was added. All four trap-related tests pass against `cpu_pipeline`.

## What is implemented

**CSR registers** (`rtl/csr_file.v`, combinational read, synchronous write):

| CSR | Address | Role here |
|---|---|---|
| mstatus | 0x300 | Readable and writable, no trap side effects yet |
| mtvec | 0x305 | Trap handler address (direct mode) |
| mepc | 0x341 | PC of the instruction that trapped |
| mcause | 0x342 | 11 = ECALL from M-mode, 2 = illegal instruction |

**Instructions:** `CSRRW`, `CSRRS`, `CSRRC` (register-operand forms), `ECALL`, `MRET`.

**Illegal-instruction detection:** the decoder raises `is_illegal` for any opcode it does not recognise, and the trap fires from EX.

## How a trap flows

1. The instruction reaches EX carrying `is_ecall`, `is_mret` or `is_illegal` (decoded in ID and carried through the ID/EX register).
2. `trap_EX = is_ecall | is_illegal`. On that cycle the CSR file saves the instruction's PC into `mepc` and the cause into `mcause`.
3. `next_pc` is redirected to `mtvec`. For `MRET` it is redirected to `mepc` instead.
4. The two younger instructions in IF and ID are flushed with the same `flush_IF_ID` and `flush_ID_EX` signals the branch logic uses, so nothing after the trapping instruction can write a register or memory.

Priority in the next-PC choice: trap or MRET first, then JALR, then a branch mispredict, then a predicted-taken fetch, then PC+4. A trap always wins because it is the most certain event.

CSR reads travel the normal datapath: `ex_result = is_csr ? csr_rdata : alu_result`, so a CSR read result forwards and writes back like any ALU result. If a trap and a CSR write land in the same cycle, the trap write wins.

## Tests

| Test | What it checks | Result |
|---|---|---|
| test_csr_rw | CSRRW, CSRRS and CSRRC read-modify-write behaviour on `mtvec` | PASS |
| test_ecall | Writes `mtvec`, executes `ECALL`, checks the two instructions after it are squashed and the handler runs | PASS |
| test_mret | Handler reads `mepc`, adds 4, writes it back, runs `MRET`, and execution resumes right after the `ECALL` | PASS |
| test_illegal | A bad instruction word (`FFFFFFFF`) traps with `mcause = 2` and the handler runs | PASS |

All programs are hand-encoded hex under `programs/`, run through self-checking testbenches under `tb/`.

## Deliberately out of scope

- Interrupts (timer, external, software), and the `mie`, `mip` and `mstatus.MIE/MPIE` handling that goes with them.
- `mtval`, `EBREAK`, misaligned-access traps, and other trap causes.
- Privilege modes other than Machine mode.
- Vectored `mtvec` (only direct mode is supported).
- The immediate CSR forms (`CSRRWI`, `CSRRSI`, `CSRRCI`); they were not part of this phase and are untested.
- `mstatus` is not updated by traps or by `MRET`.

## Known limitations

- **All-zero words never trap.** Flush bubbles in the pipeline are all-zero instruction words, so the illegal-instruction check has to ignore them. The side effect is that a genuine `0x00000000` in instruction memory runs as a no-op instead of trapping, which the spec says it should not. A cleaner fix is a separate valid bit that travels with each instruction instead of inferring "bubble" from the all-zero pattern.
- Traps resolve in EX, so each trap costs the same 2-cycle flush as a taken branch.

## Next

Part B: branch predictor. See `PHASE4_PREDICTOR_NOTES.md`.