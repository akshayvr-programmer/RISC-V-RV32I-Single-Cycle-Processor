# Phase 4C: FPGA Synthesis and Timing (Artix-7)

## Summary

The pipelined core was synthesized and implemented (place and route) in Vivado 2026.1 for the Artix-7 `xc7a35tcpg236-1`, the chip on the Digilent Basys 3. It **meets a 100 MHz clock constraint** with 0.267 ns of setup slack, uses about 1,300 LUTs and 1,400 flip-flops, and needs no block RAM or DSPs.

**It has not been flashed to a board.** There is no bitstream and no hardware test. What this phase proves is that the design synthesizes cleanly, routes, and closes timing on a real FPGA part. It does not prove behaviour on hardware.

## Target and setup

| Item | Value |
|---|---|
| Tool | Vivado 2026.1 (free Standard edition, node-locked license) |
| Part | `xc7a35tcpg236-1` (Artix-7, speed grade -1) |
| Top module | `fpga_top` (thin wrapper, `fpga/fpga_top.v`) |
| Clock constraint | 100 MHz (10 ns period), `fpga/cpu_timing.xdc` |
| Program loaded | `programs/bench_loop.hex` (the 100-lap branch benchmark) |

Changes made for synthesis:
- `cpu_pipeline` gained an output `debug_out[15:0]`, the write-back value with its upper half XORed into its lower half. Without an output that depends on the datapath, synthesis deletes the whole core as dead logic. Folding 32 bits to 16 keeps every bit alive.
- `fpga_top` wraps the CPU and points the instruction memory at the hex file with a `defparam`. The simulation testbenches are unaffected.

## Results

**Utilization (post-implementation):**

| Resource | Used | Available | Percent |
|---|---|---|---|
| Slice LUTs | 1,335 | 20,800 | 6.4% |
| of which LUT as memory | 44 | 9,600 | 0.5% |
| Slice registers (flip-flops) | 1,392 | 41,600 | 3.4% |
| Block RAM tiles | 0 | 50 | 0% |
| DSPs | 0 | 90 | 0% |
| Bonded IOBs | 18 | 106 | 17% |
| Global clock buffers | 1 | 32 | 3% |

**Timing at 100 MHz (post-route, slow corner):**

| Check | Result |
|---|---|
| Worst setup slack (WNS) | +0.267 ns (0 failing of 3,062 endpoints) |
| Worst hold slack (WHS) | +0.075 ns (0 failing) |
| Worst pulse-width slack | +3.750 ns |
| Implied maximum frequency | about 102.7 MHz (1 / (10 ns minus 0.267 ns)) |

All user-specified timing constraints are met. The raw reports are in `docs/fpga/` (`utilization_impl.txt`, `timing_summary.txt`, `critical_path.txt`).

## What limits the clock

The slowest path starts at the EX/MEM register (`RegWrite`), runs through the **forwarding mux**, then the **branch comparator** (a carry chain), then `actual_taken_EX`, then the **mispredict and flush decision**, and ends at the enable input of the IF/ID register. In words: forward, compare, decide, flush, all inside one cycle. That is the cost of resolving branches in EX with a forwarded operand.

Of the 9.13 ns data path, only 2.5 ns is logic. About 6.6 ns (72%) is routing delay, because the flush and stall decision fans out to roughly 115 flip-flops. The clock is limited by fan-out more than by gate depth.

Possible improvements (not done): duplicate the high-fan-out control signal so each copy drives fewer registers, resolve the branch comparison earlier, or register the redirect at the cost of one extra cycle on a mispredict.

## Known limitations

- **Not flashed.** No bitstream was generated and no pins are assigned to the board.
- **The numbers are for one program.** The instruction memory is a fixed ROM, so synthesis can see which instructions the benchmark never uses and remove the logic that would handle them (loads, stores and some shifts). Utilization is therefore a lower bound, and the timing result may be optimistic. A writable instruction memory would remove this effect.
- **Pins are not constrained**, so the I/O timing is not meaningful. Only register-to-register timing was checked.
- `fpga_top.v` currently contains an absolute path to the hex file, so it only builds on the author's machine until that is made portable.
- The 100 MHz target was chosen because it is the Basys 3 native clock. The true maximum was only estimated (about 102.7 MHz), not found by tightening the constraint.

## Reproduce

1. Create an RTL project for `xc7a35tcpg236-1`, add `rtl/*.v`, `fpga/fpga_top.v` and `programs/bench_loop.hex`, and add `fpga/cpu_timing.xdc` as the constraints file.
2. Set `fpga_top` as the top module (and fix the hex path in `fpga_top.v`).
3. Run Synthesis, then Implementation, then open the implemented design and run `report_timing_summary` and `report_utilization`.

## Next

Parts D and the v1.0 release: results table, demo video, license and citation file, and the tagged release.