#!/usr/bin/env python3
"""
Regression test runner for the RISC-V pipelined CPU.
Compiles and runs every testbench, checks for PASS/FAIL markers, prints a summary.

Usage:
    python run_all_tests.py
"""

import subprocess
import sys
import os

# Each entry: (friendly name, testbench file, pass marker text to search for)
TESTS = [
    ("JAL",              "tb/cpu_jal_tb.v",                 "ALL JAL TESTS PASSED"),
    ("JALR",             "tb/cpu_jalr_tb.v",                 "ALL JALR TESTS PASSED"),
    ("ALU I-type",       "tb/cpu_alu_itype_tb.v",            "ALL ALU I-TYPE TESTS PASSED"),
    ("Load-use hazard",  "tb/cpu_pipeline_loaduse_tb.v",      "LOAD-USE STALL TEST PASSED"),
    ("Branch flush",     "tb/cpu_pipeline_branch_tb.v",       "BRANCH FLUSH TEST PASSED"),
]

RTL_GLOB = "rtl/*.v"

def run_test(name, tb_file, pass_marker):
    out_file = f"_regress_{os.path.basename(tb_file)}.out"

    compile_cmd = f"iverilog -o {out_file} {RTL_GLOB} {tb_file}"
    compile_result = subprocess.run(compile_cmd, shell=True, capture_output=True, text=True)

    if compile_result.returncode != 0:
        return "COMPILE ERROR", compile_result.stderr

    run_cmd = f"vvp {out_file}"
    run_result = subprocess.run(run_cmd, shell=True, capture_output=True, text=True)
    output = run_result.stdout

    if pass_marker in output:
        return "PASS", output
    else:
        return "FAIL", output

def main():
    results = []
    print("Running regression suite...\n")

    for name, tb_file, pass_marker in TESTS:
        if not os.path.exists(tb_file):
            results.append((name, "SKIPPED (file not found)"))
            print(f"  [SKIP] {name} — {tb_file} not found")
            continue

        status, output = run_test(name, tb_file, pass_marker)
        results.append((name, status))

        symbol = "PASS" if status == "PASS" else status
        print(f"  [{symbol}] {name}")

        if status != "PASS":
            print("  ---- output ----")
            print("  " + output.replace("\n", "\n  "))
            print("  -----------------")

    print("\n=== SUMMARY ===")
    passed = sum(1 for _, s in results if s == "PASS")
    total = len(results)
    for name, status in results:
        marker = "PASS" if status == "PASS" else status
        print(f"  {name:20s} {marker}")

    print(f"\n{passed}/{total} tests passed")

    if passed != total:
        sys.exit(1)

if __name__ == "__main__":
    main()
    