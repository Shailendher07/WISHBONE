# Wishbone Bus Interface – SystemVerilog Design & Verification

## Project Overview
This project implements a Wishbone point-to-point bus interface for on-chip communication between Master and Slave IP cores in SoC designs.

The design supports:
- Single-cycle read/write transfers  
- Block/Burst transfers using CTI signaling  

Scalability verified across multiple data widths:
- 8-bit, 16-bit, 32-bit, and 64-bit

Core Wishbone signals (`cyc`, `stb`, `ack`, `we`, `adr`, `dat`, `cti`) are thoroughly verified through simulation to ensure proper timing, sequencing, and protocol adherence.

---

## Objectives
- Implement Wishbone Master and Slave with correct handshake logic  
- Support single & burst data transactions  
- Ensure valid address & data sequencing during burst operations  
- Develop a SystemVerilog testbench ensuring complete protocol compliance  

---

## Master Design
The Master module follows an FSM-based architecture with:
- **IDLE**, **BUS_REQUEST**, **BUS_WAIT** states  

It generates key control signals:
- `cyc_o`, `stb_o`, `we_o`, `sel_o`, `adr_o`, `dat_o`, `cti_o`

Features:
- Handles both classic and burst transfers  
- Terminates burst with **CTI = 3'b111**  
- Captures Slave responses (`ack_i`, `err_i`)  

---

## Slave Design
A synchronous memory-based Wishbone Slave supporting:
- Read, Write, Burst access modes  

### CTI Mode Support
| CTI Code | Operation Type |
|---------|----------------|
| `000` | Classic single transfer |
| `001` | Incrementing burst |
| `010` | Linear burst |
| `111` | Burst end |

Additional Features:
- Burst counter to maintain sequencing  
- Generates **ACK** and **ERR** responses  
- **Tag-Add** feature: returns `mem[0] + mem[1]`  

---

## Top-Level Integration
- Connects Master and Slave together for functional Wishbone operation  
- Ensures proper handshake and CTI decoding  
- Includes debug (`dbg_*`) signals to aid waveform monitoring  

---

## Verification Environment
A modular SystemVerilog testbench with:
- **Generator** → Constrained-random stimulus  
- **Driver** → Drives bus protocol signals  
- **Monitor** → Observes Wishbone transactions  
- **Scoreboard** → Reference memory for data checking  

Verification targets:
- Handshake correctness  
- Burst sequencing and timing  
- ACK/ERR behavior  
- Data integrity and Tag-Add correctness  
- Burst completion using `CTI = 3'b111`  

---

## Test Scenarios
- Classic read/write operations  
- Incrementing & linear burst transfers  
- Burst termination using CTI End code  
- Invalid address → error signaling  

---

## Simulation Results
Waveform & log-based functional validation confirm:
- Correct Wishbone timing and state transitions  
- Accurate read/write data transactions  
- Proper ACK/ERR signaling  
- Full protocol compliance under burst conditions  
