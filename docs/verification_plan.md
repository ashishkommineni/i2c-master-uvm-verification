# Verification Plan

The behavioral slave decodes the real serial bus, returns configurable ACK/NACK on each of two phases, and exposes captured address/data to the scoreboard. UVM randomizes legal addresses, payloads, and address/data NACK injection. Coverage distinguishes ACK, address NACK, data NACK, and payload classes. Assertions check command acceptance, one-cycle completion, and known open-drain lines.
