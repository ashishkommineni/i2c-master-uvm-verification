# I²C Master Write Specification

## Supported transaction

The DUT implements one-master, 7-bit-address, single-byte writes at a controller-defined SCL rate:

`START → address[6:0] → W(0) → ACK → data[7:0] → ACK → STOP`

`start` is accepted only while idle. The controller then raises `busy`, clears the previous `ack_error`, and emits both bytes MSB first. `done` pulses for one controller clock after STOP completes.

## Electrical model

SDA and SCL are open-drain controls. `*_drive_low=1` pulls a line low; zero releases it. The master never actively drives a one. External pull-ups and the verification slave determine the observed `sda_in` and `scl_in` values.

During each high phase, the controller waits until `scl_in` is actually high. A target may therefore stretch the clock by holding SCL low. The master releases SDA for each ACK slot and samples the observed line. `ack_error` is sticky within a transaction and reports a NACK in either the address or data phase.

## Configuration and reset

`CLK_DIV` is at least two and determines the number of controller clocks per internal I²C phase. Active-low asynchronous reset returns both lines to the released state and clears `busy`, `done`, and error state.

## Deliberate boundaries

Arbitration, repeated START, reads, 10-bit addressing, multi-byte transfers, programmable bus timing, and multi-master synchronization are not claimed. The UVM item constrains ordinary unreserved 7-bit target addresses (`0x08–0x77`).
