# RISC-V Single-Cycle Processor (RV32I Subset) in Verilog

A fully functional **RV32I Single-Cycle Processor** implemented from scratch in **Verilog HDL**. This project implements the core datapath and control logic required to execute a subset of the RISC-V RV32I ISA and is being extended toward complete RV32I support.

---

## Features

- RV32I Single-Cycle Datapath
- Modular Verilog Design
- Harvard Architecture
- 32 × 32-bit Register File
- ALU with Arithmetic and Logical Operations
- Immediate Generator
- Main Control Unit
- ALU Control Unit
- Instruction Memory
- Data Memory
- Load/Store Support
- Branch Infrastructure
- Cycle-accurate Simulation using Icarus Verilog

---

## Current Instruction Support

### Arithmetic

- ADD
- SUB
- ADDI

### Logical

- AND
- OR
- XOR
- SLT

### Memory

- LW
- SW

### Branch

- BEQ (Datapath implemented)

---

## Processor Architecture

```
                 +----------------+
                 | Program Counter|
                 +--------+-------+
                          |
                          v
               +----------------------+
               | Instruction Memory   |
               +----------+-----------+
                          |
          +---------------+----------------+
          |                                |
          v                                v
   Control Unit                 Immediate Generator
          |                                |
          |                                |
          v                                |
    Register File -------------------------+
          |                    |
          |                    |
          v                    v
               ALU Source MUX
                     |
                     v
                    ALU
                     |
          +----------+-----------+
          |                      |
          v                      |
      Data Memory                |
          |                      |
          +----------+-----------+
                     |
                     v
              Write Back MUX
                     |
                     v
              Register File
```

---

## Directory Structure

```
RISC-V-RV32I/
│
├── rtl/
│   ├── pc.v
│   ├── instruction_memory.v
│   ├── register_file.v
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
│   └── cpu.v
│
├── tb/
│   └── cpu_tb.v
│
├── programs/
│   └── test.hex
│
├── docs/
│
└── README.md
```

---

## Verification

The processor has been validated using simulation in **Icarus Verilog**.

Verified functionality includes:

- Register reads and writes
- Immediate generation
- ALU arithmetic operations
- Logical operations
- Load/Store instructions
- Instruction fetch
- Write-back path
- Program Counter update

Example execution:

| Instruction | Result |
|------------|-------:|
| `addi x1,x0,5` | ✔ |
| `addi x2,x0,10` | ✔ |
| `add x3,x1,x2` | ✔ |
| `sub x4,x2,x1` | ✔ |
| `and x5,x1,x2` | ✔ |
| `or x6,x1,x2` | ✔ |
| `xor x7,x1,x2` | ✔ |
| `sw x3,0(x0)` | ✔ |
| `lw x9,0(x0)` | ✔ |

---

## Tools Used

- Verilog HDL
- Icarus Verilog
- VS Code

---

## Future Work

- Complete RV32I instruction support
- JAL / JALR
- LUI / AUIPC
- Additional branch instructions
- Pipeline implementation
- Hazard detection
- Forwarding Unit
- Branch Prediction
- Automated assembly-to-hex toolchain
- Comprehensive test suite

---

## Author

**Akshay V R**

B.Tech Electronics & Communication Engineering

Netaji Subhas University of Technology (NSUT)
