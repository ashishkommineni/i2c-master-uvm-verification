# I²C Master Write Specification

The DUT implements one-master, 7-bit-address, single-byte write transactions: START, address plus write bit, address ACK, eight data bits, data ACK, and STOP. SDA and SCL are modeled as open-drain controls: the master may pull a line low or release it; external pull-ups create logic high. The master waits for observed `scl_in` before completing a high phase, allowing clock stretching. `ack_error` accumulates a NACK from either ACK slot.

Arbitration, repeated START, reads, 10-bit addressing, and multi-byte transfers are outside this deliberately bounded portfolio version.
