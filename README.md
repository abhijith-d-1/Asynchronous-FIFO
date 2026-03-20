# Parameterized Asynchronous FIFO (Verilog)

A high-performance, **Clock Domain Crossing (CDC)** safe Asynchronous FIFO. This design is engineered to reliably transfer data between two independent clock domains using Gray code pointer synchronization and double-flop synchronizers.

## Technical Overview
In digital systems, transferring data between asynchronous clock domains can lead to **metastability**. This project implements a classic, robust architecture to mitigate these risks.

### Key Features:
* **Dual-Clock Architecture**: Independent `w_clk` (Write) and `r_clk` (Read).
* **Metastability Guard**: 2-stage (Double-Flop) synchronizers for all cross-domain signals.
* **Gray Code Encoding**: Pointer synchronization uses Gray code to ensure only **one bit** changes per clock cycle, eliminating multi-bit synchronization errors.
* **Full/Empty Look-ahead**: High-speed flag logic for immediate flow control.
* **Modular Testbench**: Built using **Verilog Tasks** to simulate complex scenarios like burst writes, buffer draining, and interleaved CDC stress tests.

---

## System Architecture

![Asynchronous FIFO Block Diagram](https://github.com/abhijith-d-1/Asynchronous-FIFO/blob/48451ea77ad9a03ba668f9e3743dc45e23309dba/Block%20diagram.jpg)

### The "Top Two Bits" Logic
Detecting the `full` condition in an Async FIFO is non-trivial. Unlike binary pointers, Gray code is reflective. To determine if the Write Pointer has "lapped" the Read Pointer (Full), we apply the following logic:
1. **MSB** must be inverted.
2. **2nd MSB** must be inverted.
3. **All remaining LSBs** must match.

$$full = (g\_wptr == \{\sim g\_rptr\_sync[MSB:MSB-1], g\_rptr\_sync[MSB-2:0]\})$$

---

## Simulation Scenarios
The included testbench (`Async_FIFO_tb.v`) verifies the design through three critical phases:

1. **Basic Write/Read**: Verifies single-word integrity and registered output timing.
2. **Burst to Full**: Fills the FIFO to its limit to ensure the `full` flag correctly back-pressures the source.
3. **Drain to Empty**: Reads until the buffer is dry to verify the `empty` flag correctly halts the sink.

