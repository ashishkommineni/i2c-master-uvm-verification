# Verification Plan

## Strategy

The UVM driver programs a command-level request, but checking occurs on the physical open-drain bus. A behavioral target decodes START, both transmitted bytes, ACK slots, and STOP; it can NACK the address or data phase. The monitor pairs the accepted request with decoded bus results and completion status.

| Goal | Stimulus | Check |
|---|---|---|
| Successful write | Directed ACK/ACK transfer | Captured address/data and `ack_error=0` |
| Address NACK | Directed phase-1 NACK | `ack_error=1`, decoded bytes preserved |
| Data NACK | Directed phase-2 NACK | `ack_error=1`, STOP still produced |
| Address range | Constrained `0x08–0x77` targets | Legal-low/mid/high cover bins |
| Payload patterns | Random plus `00`, `FF`, `55`, `AA` classes | Data coverage and scoreboard |
| Open-drain behavior | Every serial phase | Drive-low-to-observed-low SVA |

## Constraints and coverage

The transaction restricts targets to ordinary unreserved 7-bit addresses. NACK injection is weighted toward successful traffic while retaining both negative cases. Coverage crosses payload class with ACK/address-NACK/data-NACK outcome; reserved-address bins are explicitly illegal rather than unreachable coverage goals.

## Assertions and closure

Assertions check start-to-busy response, one-cycle `done`, known bus/drive values, and the open-drain rule for both SCL and SDA. Closure requires zero UVM errors/fatals, passing SVA, all intended ACK/NACK and payload bins, and the serial-decoding smoke PASS token.
