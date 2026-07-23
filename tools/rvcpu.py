#!/usr/bin/env python3
"""
rvcpu - build / run / assemble helper for the RV32I single-cycle processor.

Usage:
    python tools/rvcpu.py build
    python tools/rvcpu.py asm programs/test.s -o programs/test.hex
    python tools/rvcpu.py run programs/test.s
    python tools/rvcpu.py run programs/test.hex --vcd
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------- paths ----

ROOT = Path(__file__).resolve().parent.parent
RTL_DIR = ROOT / "rtl"
TB_DIR = ROOT / "tb"
PROG_DIR = ROOT / "programs"
BUILD_DIR = ROOT / "build"
SIM_BIN = BUILD_DIR / ("cpu_sim.vvp")

# The file your testbench feeds to $readmemh. `run` copies whatever hex you
# give it here before launching the simulation.
MEM_FILE = PROG_DIR / "test.hex"


def info(msg):
    print(f"[rvcpu] {msg}")


def die(msg, code=1):
    print(f"[rvcpu] error: {msg}", file=sys.stderr)
    sys.exit(code)


# ------------------------------------------------------------ assembler ----

REGISTERS = {f"x{i}": i for i in range(32)}
REGISTERS.update({
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13,
    "a4": 14, "a5": 15, "a6": 16, "a7": 17,
    "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22,
    "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31,
})

# mnemonic -> (format, opcode, funct3, funct7)
ISA = {
    # R-type, opcode 0110011
    "add":  ("R", 0b0110011, 0b000, 0b0000000),
    "sub":  ("R", 0b0110011, 0b000, 0b0100000),
    "sll":  ("R", 0b0110011, 0b001, 0b0000000),
    "slt":  ("R", 0b0110011, 0b010, 0b0000000),
    "sltu": ("R", 0b0110011, 0b011, 0b0000000),
    "xor":  ("R", 0b0110011, 0b100, 0b0000000),
    "srl":  ("R", 0b0110011, 0b101, 0b0000000),
    "sra":  ("R", 0b0110011, 0b101, 0b0100000),
    "or":   ("R", 0b0110011, 0b110, 0b0000000),
    "and":  ("R", 0b0110011, 0b111, 0b0000000),

    # I-type arithmetic, opcode 0010011
    "addi":  ("I", 0b0010011, 0b000, None),
    "slti":  ("I", 0b0010011, 0b010, None),
    "sltiu": ("I", 0b0010011, 0b011, None),
    "xori":  ("I", 0b0010011, 0b100, None),
    "ori":   ("I", 0b0010011, 0b110, None),
    "andi":  ("I", 0b0010011, 0b111, None),

    # Loads, opcode 0000011
    "lb":  ("L", 0b0000011, 0b000, None),
    "lh":  ("L", 0b0000011, 0b001, None),
    "lw":  ("L", 0b0000011, 0b010, None),
    "lbu": ("L", 0b0000011, 0b100, None),
    "lhu": ("L", 0b0000011, 0b101, None),

    # Stores, opcode 0100011
    "sb": ("S", 0b0100011, 0b000, None),
    "sh": ("S", 0b0100011, 0b001, None),
    "sw": ("S", 0b0100011, 0b010, None),

    # Branches, opcode 1100011
    "beq":  ("B", 0b1100011, 0b000, None),
    "bne":  ("B", 0b1100011, 0b001, None),
    "blt":  ("B", 0b1100011, 0b100, None),
    "bge":  ("B", 0b1100011, 0b101, None),
    "bltu": ("B", 0b1100011, 0b110, None),
    "bgeu": ("B", 0b1100011, 0b111, None),
}

# What your RTL actually executes today. Anything outside this set still
# assembles correctly, but the CLI warns you that the hardware will not run it.
HW_SUPPORTED = {"add", "sub", "addi", "and", "or", "xor", "slt", "lw", "sw", "beq"}


class AsmError(Exception):
    pass


def parse_reg(tok, lineno):
    name = tok.strip().lower()
    if name not in REGISTERS:
        raise AsmError(f"line {lineno}: unknown register '{tok}'")
    return REGISTERS[name]


def parse_imm(tok, lineno):
    tok = tok.strip()
    try:
        return int(tok, 0)  # handles 10, 0x1f, 0b101, -4
    except ValueError:
        raise AsmError(f"line {lineno}: bad immediate '{tok}'")


def check_range(value, bits, lineno, what="immediate"):
    lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    if not lo <= value <= hi:
        raise AsmError(
            f"line {lineno}: {what} {value} does not fit in {bits} signed bits "
            f"(allowed {lo}..{hi})"
        )


def split_operands(text):
    return [p for p in re.split(r"[,\s]+", text.strip()) if p]


MEM_OPERAND = re.compile(r"^(-?\w+)\(\s*(\w+)\s*\)$")


def encode(mnemonic, operands, pc, labels, lineno):
    fmt, opcode, funct3, funct7 = ISA[mnemonic]

    if fmt == "R":
        if len(operands) != 3:
            raise AsmError(f"line {lineno}: {mnemonic} needs rd, rs1, rs2")
        rd = parse_reg(operands[0], lineno)
        rs1 = parse_reg(operands[1], lineno)
        rs2 = parse_reg(operands[2], lineno)
        return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | \
               (funct3 << 12) | (rd << 7) | opcode

    if fmt == "I":
        if len(operands) != 3:
            raise AsmError(f"line {lineno}: {mnemonic} needs rd, rs1, imm")
        rd = parse_reg(operands[0], lineno)
        rs1 = parse_reg(operands[1], lineno)
        imm = parse_imm(operands[2], lineno)
        check_range(imm, 12, lineno)
        return ((imm & 0xFFF) << 20) | (rs1 << 15) | \
               (funct3 << 12) | (rd << 7) | opcode

    if fmt == "L":
        if len(operands) != 2:
            raise AsmError(f"line {lineno}: {mnemonic} needs rd, offset(rs1)")
        rd = parse_reg(operands[0], lineno)
        m = MEM_OPERAND.match(operands[1])
        if not m:
            raise AsmError(f"line {lineno}: expected offset(rs1), got '{operands[1]}'")
        imm = parse_imm(m.group(1), lineno)
        rs1 = parse_reg(m.group(2), lineno)
        check_range(imm, 12, lineno, "offset")
        return ((imm & 0xFFF) << 20) | (rs1 << 15) | \
               (funct3 << 12) | (rd << 7) | opcode

    if fmt == "S":
        if len(operands) != 2:
            raise AsmError(f"line {lineno}: {mnemonic} needs rs2, offset(rs1)")
        rs2 = parse_reg(operands[0], lineno)
        m = MEM_OPERAND.match(operands[1])
        if not m:
            raise AsmError(f"line {lineno}: expected offset(rs1), got '{operands[1]}'")
        imm = parse_imm(m.group(1), lineno)
        rs1 = parse_reg(m.group(2), lineno)
        check_range(imm, 12, lineno, "offset")
        imm &= 0xFFF
        return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | \
               (funct3 << 12) | ((imm & 0x1F) << 7) | opcode

    if fmt == "B":
        if len(operands) != 3:
            raise AsmError(f"line {lineno}: {mnemonic} needs rs1, rs2, label")
        rs1 = parse_reg(operands[0], lineno)
        rs2 = parse_reg(operands[1], lineno)
        target = operands[2]
        if target in labels:
            offset = labels[target] - pc
        else:
            offset = parse_imm(target, lineno)
        if offset % 2 != 0:
            raise AsmError(f"line {lineno}: branch target must be even")
        check_range(offset, 13, lineno, "branch offset")
        imm = offset & 0x1FFF
        b12 = (imm >> 12) & 1
        b10_5 = (imm >> 5) & 0x3F
        b4_1 = (imm >> 1) & 0xF
        b11 = (imm >> 11) & 1
        return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | \
               (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode

    raise AsmError(f"line {lineno}: unhandled format for '{mnemonic}'")


def expand_pseudo(mnemonic, operands):
    """Rewrite a few conveniences into real instructions."""
    if mnemonic == "nop":
        return "addi", ["x0", "x0", "0"]
    if mnemonic == "mv":
        return "addi", [operands[0], operands[1], "0"]
    if mnemonic == "li":
        return "addi", [operands[0], "x0", operands[1]]
    if mnemonic == "j":
        return "beq", ["x0", "x0", operands[0]]
    if mnemonic == "beqz":
        return "beq", [operands[0], "x0", operands[1]]
    if mnemonic == "bnez":
        return "bne", [operands[0], "x0", operands[1]]
    return mnemonic, operands


def clean_lines(text):
    """Yield (lineno, label_or_None, mnemonic, operands) for real instructions."""
    out = []
    for lineno, raw in enumerate(text.splitlines(), start=1):
        line = raw.split("#")[0].split("//")[0].strip()
        if not line:
            continue
        while ":" in line:
            label, _, rest = line.partition(":")
            out.append((lineno, label.strip(), None, None))
            line = rest.strip()
        if not line:
            continue
        parts = line.split(None, 1)
        mnemonic = parts[0].lower()
        operands = split_operands(parts[1]) if len(parts) > 1 else []
        out.append((lineno, None, mnemonic, operands))
    return out


def assemble(text, base_address=0):
    items = clean_lines(text)

    # Pass 1: resolve label addresses.
    labels, pc = {}, base_address
    for lineno, label, mnemonic, operands in items:
        if label is not None:
            if label in labels:
                raise AsmError(f"line {lineno}: duplicate label '{label}'")
            labels[label] = pc
        else:
            pc += 4

    # Pass 2: encode.
    words, listing, warnings, pc = [], [], [], base_address
    for lineno, label, mnemonic, operands in items:
        if label is not None:
            continue
        real_mnemonic, real_operands = expand_pseudo(mnemonic, operands)
        if real_mnemonic not in ISA:
            raise AsmError(f"line {lineno}: unknown instruction '{mnemonic}'")
        if real_mnemonic not in HW_SUPPORTED:
            warnings.append(
                f"line {lineno}: '{mnemonic}' assembles fine but your RTL "
                f"does not implement it yet"
            )
        word = encode(real_mnemonic, real_operands, pc, labels, lineno)
        words.append(word)
        listing.append((pc, word, f"{mnemonic} {' '.join(operands)}".strip()))
        pc += 4

    return words, listing, warnings


# ------------------------------------------------------------- commands ----

def verilog_sources():
    rtl = sorted(RTL_DIR.glob("*.v"))
    tb = sorted(TB_DIR.glob("*.v"))
    if not rtl:
        die(f"no .v files found in {RTL_DIR}")
    if not tb:
        die(f"no testbench found in {TB_DIR}")
    return rtl, tb


def cmd_build(args):
    if shutil.which("iverilog") is None:
        die("iverilog not found on PATH - install Icarus Verilog first")

    rtl, tb = verilog_sources()
    BUILD_DIR.mkdir(exist_ok=True)

    cmd = ["iverilog", "-g2012", "-o", str(SIM_BIN)]
    cmd += [str(p) for p in rtl + tb]

    info(f"compiling {len(rtl)} RTL file(s) + {len(tb)} testbench file(s)")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        die("compilation failed", result.returncode)
    info(f"built {SIM_BIN.relative_to(ROOT)}")
    return 0


def cmd_asm(args):
    src = Path(args.source)
    if not src.exists():
        die(f"{src} not found")

    try:
        words, listing, warnings = assemble(src.read_text(), args.base)
    except AsmError as e:
        die(str(e))

    for w in warnings:
        print(f"[rvcpu] warning: {w}", file=sys.stderr)

    out = Path(args.output) if args.output else src.with_suffix(".hex")
    out.parent.mkdir(parents=True, exist_ok=True)

    lines = []
    for pc, word, source in listing:
        if args.comments:
            lines.append(f"{word:08x}   // {pc:04x}: {source}")
        else:
            lines.append(f"{word:08x}")
    out.write_text("\n".join(lines) + "\n")

    info(f"assembled {len(words)} instruction(s) -> {out}")
    if args.listing:
        print()
        for pc, word, source in listing:
            print(f"  {pc:04x}  {word:08x}  {source}")
    return 0


def cmd_run(args):
    target = Path(args.program)
    if not target.exists():
        die(f"{target} not found")

    # Accept assembly directly - assemble it on the fly.
    if target.suffix in (".s", ".asm"):
        try:
            words, listing, warnings = assemble(target.read_text())
        except AsmError as e:
            die(str(e))
        for w in warnings:
            print(f"[rvcpu] warning: {w}", file=sys.stderr)
        hex_text = "\n".join(f"{w:08x}" for w in words) + "\n"
        info(f"assembled {target.name} ({len(words)} instructions)")
    else:
        hex_text = target.read_text()

    if not SIM_BIN.exists():
        info("no simulation binary yet, building first")
        cmd_build(args)

    MEM_FILE.parent.mkdir(parents=True, exist_ok=True)
    MEM_FILE.write_text(hex_text)

    if shutil.which("vvp") is None:
        die("vvp not found on PATH - it ships with Icarus Verilog")

    cmd = ["vvp", str(SIM_BIN)]
    if args.vcd:
        cmd += ["+vcd"]

    info(f"running {target.name}")
    print("-" * 56)
    result = subprocess.run(cmd, cwd=ROOT)
    print("-" * 56)
    if result.returncode != 0:
        die("simulation exited non-zero", result.returncode)
    return 0


def cmd_clean(args):
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
        info(f"removed {BUILD_DIR.relative_to(ROOT)}/")
    for vcd in ROOT.glob("*.vcd"):
        vcd.unlink()
        info(f"removed {vcd.name}")
    return 0


# ----------------------------------------------------------------- main ----

def main():
    parser = argparse.ArgumentParser(
        prog="rvcpu",
        description="Build, assemble for, and simulate the RV32I single-cycle processor.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_build = sub.add_parser("build", help="compile the RTL and testbench with iverilog")
    p_build.set_defaults(func=cmd_build)

    p_asm = sub.add_parser("asm", help="assemble a .s file into a .hex memory image")
    p_asm.add_argument("source", help="assembly source file")
    p_asm.add_argument("-o", "--output", help="output .hex path")
    p_asm.add_argument("--base", type=lambda v: int(v, 0), default=0,
                       help="base address for label resolution (default 0)")
    p_asm.add_argument("--comments", action="store_true",
                       help="annotate the hex output with source lines")
    p_asm.add_argument("--listing", action="store_true",
                       help="print an address/encoding/source listing")
    p_asm.set_defaults(func=cmd_asm)

    p_run = sub.add_parser("run", help="simulate a program (.s or .hex)")
    p_run.add_argument("program", help="assembly or hex file to run")
    p_run.add_argument("--vcd", action="store_true", help="pass +vcd to the testbench")
    p_run.set_defaults(func=cmd_run)

    p_clean = sub.add_parser("clean", help="remove build artifacts and waveforms")
    p_clean.set_defaults(func=cmd_clean)

    args = parser.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()