# Superscalar Processor Design
In-order superscalar RV32I processor project for SoC 2025.

## Overview

This project aims at implementing my understanding of key processor architecture concepts covered in recent lectures and YouTube videos, including:

* **Pipelining**: Overlapping instruction fetch, decode, execute, memory, and write-back stages to improve instruction throughput.
* **Superscalar Architecture**: Fetching and issuing multiple instructions per cycle (dual-issue) to exploit instruction-level parallelism.
* **Out-of-Order Execution**: Dynamically scheduling independent instructions around hazards to minimize stalls and improve performance.
* **Branch Handling**: Detecting, predicting, and flushing or redirecting the pipeline on control hazards to maintain correct program flow.

## Implemented VHDL Components

I have started writing VHDL code for the following modules. Each component includes its interface and a brief description of its functionality.

### 1. [InstructionFetch](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/InstructionDecoder.vhd)

* **Purpose**: Fetches two 32-bit RV32I instructions per cycle and updates the program counter (PC).
* **Inputs**:

  * `clk`        : Clock signal
  * `reset`      : Asynchronous reset
  * `BranchTaken`: Indicates a taken branch
  * `BranchTarget`: New PC on branch
  * `Stall`      : Pipeline stall signal
  * `Flush`      : Control hazard flush signal
* **Outputs**:

  * `Instr1`     : First fetched instruction (32 bits)
  * `Instr2`     : Second fetched instruction (32 bits)
  * `PC_plus4`   : PC + 4 (next instruction address)
  * `PC_plus8`   : PC + 8 (address for following cycle)
  * `Fetch_Valid`: Indicates fetched instructions are valid
  * `PC_out`     : Current PC value (for tracing)

### 2. [IF\_ID\_Register](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/IF_ID_pipeline_reg.vhd)

* **Purpose**: Pipeline register between IF and ID stages, holding fetched instructions and PC values.
* **Inputs**:

  * `clk`        : Clock signal
  * `Stall`      : Hold register contents when asserted
  * `Flush`      : Inject bubble (NOPs) when asserted
  * `Instr1_in`  : Instruction 1 from IF
  * `Instr2_in`  : Instruction 2 from IF
  * `PC_in`      : Current PC (7 bits)
  * `NPC_in`     : Next PC (7 bits)
  * `Valid_in`   : Fetch validity
* **Outputs**:

  * `Instr1_out` : Instruction 1 to ID
  * `Instr2_out` : Instruction 2 to ID
  * `PC_out`     : PC to ID
  * `NPC_out`    : Next PC to ID
  * `Valid_out`  : Validity to ID

### 3. [InstructionDecoder](https://github.com/SreestiXD/Superscalar-Processor-Design-/blob/main/Superscalar.vhd)

* **Purpose**: Parses a 32-bit instruction into fields and sign-extended immediates for all RV32I formats.
* **Inputs**:

  * `instruction`: Raw 32-bit instruction word
* **Outputs**:

  * `opcode`     : Bits \[6:0]
  * `rd`         : Destination register \[11:7]
  * `funct3`     : Function code \[14:12]
  * `rs1`        : Source register 1 \[19:15]
  * `rs2`        : Source register 2 \[24:20]
  * `funct7`     : Function code \[31:25]
  * `imm_I`      : Sign-extended I-type immediate
  * `imm_S`      : Sign-extended S-type immediate
  * `imm_B`      : Sign-extended B-type immediate
  * `imm_U`      : U-type immediate (lower 12 bits zero)
  * `imm_J`      : Sign-extended J-type immediate
  * `shamt`      : Shift amount \[24:20]

## Work in Progress

Development of downstream pipeline stages (ID/EX, EX/MEM, MEM/WB) and branch-prediction mechanisms is ongoing.
