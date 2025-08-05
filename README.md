# Superscalar Processor Design
In-order superscalar RV32I processor project for SoC 2025.

## Overview

This project aims at implementing my understanding of key processor architecture concepts covered in recent lectures and YouTube videos, including:

* **Pipelining**: Overlapping instruction fetch, decode, execute, memory, and write-back stages to improve instruction throughput.
* **Superscalar Architecture**: Fetching and issuing multiple instructions per cycle (dual-issue) to exploit instruction-level parallelism.
* **Out-of-Order Execution**: Dynamically scheduling independent instructions around hazards to minimize stalls and improve performance.
* **Branch Handling**: Detecting, predicting, and flushing or redirecting the pipeline on control hazards to maintain correct program flow.

This repository contains a structural, dual-issue, in-order superscalar processor designed in VHDL, implementing the RV32I RISC-V ISA. The processor is built from the ground up using modular components and simulates pipelined execution from fetch to write-back.

My Processor Design can be found here: [MyDesign.pdf](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/MyDesign.pdf)

A video explanation of my design can be found here : [Video](https://drive.google.com/file/d/1tI-WKLwZLbh0TnXV2Cg0qMGcl2rOY14y/view?usp=sharing)

---

## Features

- **Dual-Issue Superscalar Execution**: The processor fetches, decodes, and executes two instructions per cycle while maintaining strict **in-order** semantics.
- **Fully Structural Design**: No behavioral processes in the top-level — every module is instantiated and wired explicitly.
- **Instruction Bundling**: All control and data signals are encapsulated per instruction into structured `InstructionBundle` records.
- **Intelligent Scheduling**: A combination of **FIFO**, **scheduler**, and **scoreboard** ensures only data-ready instructions proceed to execution.
- **Register File with 2R1W**: A single register file supports two simultaneous reads and one write per cycle.
- **Pipelined Execution**: IF → ID → EX → MEM → WB
- **RV32I ISA Support**: Implements arithmetic, immediate, memory, and control flow instructions from RV32I 
- **Simulation-Ready**: Outputs from the final MEM/WB stage can be probed for testing and verification.

---

## Component Descriptions

| Component             | Description |
|-----------------------|-------------|
| [**InstructionFetch**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/Superscalar.vhd)  | Fetches two 32-bit instructions per cycle from instruction memory (ROM-based). Computes `PC+4`, `PC+8`, and handles jump/branch redirection. |
| [**IF_ID Pipeline Register**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/IF_ID_pipeline_reg.vhd) | Stores fetched instructions, PCs, and valid bits to be passed into the decode stage. |
| [**InstructionDecoder**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/InstructionDecoder.vhd) | Extracts opcode, rd, rs1, rs2, funct3, funct7, and decodes all relevant immediates (I, S, B, U, J). |
| [**ControlUnit**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/ControlUnit.vhd)       | For each instruction, generates ALU operation, jump flags, memory control, and source select signals. |
| [**InstructionBundler**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/InstructionBundler.vhd) | Combines decoded fields and control signals into a structured `InstructionBundle` for downstream pipeline use. |
| [**FIFOqueue**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/FIFOqueue.vhd)         | Buffers bundled instructions until the scheduler can issue them. Supports one/two instruction entry/exit per cycle. |
| [**Schedular**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/Schedular.vhd)         | Selects ready instructions from FIFO based on register availability using the scoreboard. Issues up to two per cycle. |
| [**Scoreboard**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/Scoreboard.vhd)        | Tracks busy/available status of each register. Set by scheduler, cleared on write-back. Prevents RAW hazards. |
| [**RegisterFile**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/RegisterFile.vhd)      | 32-register file with 2 read ports (for dual issue) and 1 write port. Supports simultaneous reads for both instructions. |
| [**Mux2x1_32bit**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/2x1mux_32bit.vhd)      | Selects between `rs1` value and PC for ALU input 1 (used in jumps and AUIPC). |
| [**Mux6x1_32bit**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/Mux6x1_32bit.vhd)      | Selects between multiple immediate types or `rs2` for ALU input 2, based on instruction type. |
| [**ALU**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/ALU.vhd)               | Performs arithmetic, logical, and comparison operations. Result and zero flag used for further control (e.g., branches). |
| [**EX_MEM Register**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/EX_MEM_Register.vhd)   | Stores ALU results and instruction bundles to be passed to the MEM stage. |
| [**DataMemory**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/DataMemory.vhd)        | Word-addressed memory (4KB). Shared between both instructions with priority logic to avoid write conflicts. |
| [**Mux2x1_32bit (WB)**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/2x1mux_32bit.vhd) | Selects between ALU result and DataMemory output for final write-back value. |
| [**MEM_WB Register**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/MEM_WB_Register.vhd)   | Captures final result and bundle per instruction before writing back to the register file. |
| [**WriteBackMux**](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/WriteBackMux.vhd)      | Chooses which instruction writes back to the register file (issue 0 prioritized) when only one write port is available. |
