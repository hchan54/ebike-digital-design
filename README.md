# Ebike Controller

This project contains RTL and verification collateral for a small e‑bike controller implemented in SystemVerilog and prototyped on the Terasic DE0‑SoC (Cyclone V). The design integrates sensor inputs over UART/SPI, produces PWM drive signals for motor control, and includes self‑checking testbenches, timing analysis guidance, and resource/area notes from synthesis.

## Highlights

SystemVerilog RTL + self‑checking testbenches (ModelSim)

UART (8N1, configurable baud) and SPI (Mode 0/3) drivers

PWM motor controller with duty‑cycle ramp limiting

Clean clock‑domain handling and parameterized design via pkg_params.sv

Synthesis targets and pin/SDC stubs for DE0‑SoC

Notes on timing closure and area mapping trade‑offs

## Requirements

Intel Quartus Prime (Lite/Std) + ModelSim‑Intel FPGA Edition

Terasic DE0‑SoC (or any Cyclone V board with PIN/SDC updates)

Optional: Python 3.x for simple stimulus/log parsing

