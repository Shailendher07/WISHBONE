Wishbone Bus Interface – Design and Verification (SystemVerilog)
Overview

This project implements a Wishbone point-to-point bus interface for on-chip communication between Master and Slave IP cores in SoC designs.
The design supports:

Single-cycle read/write transfers

Block/burst transfers using CTI signaling

Scalability is demonstrated across data widths: 8-bit, 16-bit, 32-bit, and 64-bit.
Protocol correctness for core Wishbone signals (cyc, stb, ack, we, adr, dat, cti) is thoroughly verified through simulation.

Objectives

Implement Wishbone Master and Slave with proper handshake behavior

Support both single and burst transfers

Ensure correct address sequencing and timing

Develop SystemVerilog verification environment for protocol compliance

Master Design

FSM-based design with:

IDLE, BUS_REQUEST, BUS_WAIT states

Generates key control signals:

cyc_o, stb_o, we_o, sel_o, adr_o, dat_o, cti_o

Handles single + block transfers with Burst-End signaling

Captures Slave responses (ACK, ERR)

Slave Design

Synchronous memory supporting:

Read, write, burst access

CTI support:

000 → Classic single transfer

001 → Incrementing burst

010 → Linear burst

111 → Burst End

Burst counter for block transfer sequencing

Error generation for invalid access

Tag-Add feature: returns mem[0] + mem[1]

Top-Level Integration

Combines Master + Slave into a Wishbone interconnect

Ensures correct timing for CTI-based burst execution

Exposes debug signals for waveform analysis

Verification Environment

Structured SystemVerilog testbench consisting of:

Generator → Constrained-random stimulus

Driver → Drives protocol-valid signal sequences

Monitor → Observes bus behavior

Scoreboard → Validates memory integrity

Verification ensures:

Correct handshake and protocol sequencing

Wait-state handling in burst transfers

Proper ACK/ERR behavior

Validity of Tag-Add operations

Burst completion using cti = 111

Test Scenarios

Classic read/write cycles

Incrementing & Linear burst sequences

Burst termination

Invalid address detection & ERR response

Simulation Results

Waveform and log-based validation confirms:

Accurate bus timing and state transitions

Data integrity in single and burst transactions

Proper CTI decoding and burst addressing

Functional Tag-Add support
