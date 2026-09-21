# Verification Results

Revalidated: 2026-09-21

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint`; zero RTL warnings |
| Executable serial + SVA smoke | PASS | `I2C_SMOKE_PASS checks=3` |
| Parameter elaboration | PASS | Non-power-of-two `CLK_DIV=3` variant passed strict lint |
| UVM source compile/elaboration | PASS | Master, bus interface, target model, SVA, package, and top compiled with Accellera UVM `78c0654` |

```text
I2C_SMOKE_PASS checks=3
```

The target model decodes the real SDA/SCL transaction rather than reading internal DUT state. The three checks cover ACK success, address NACK, and data NACK while validating START/STOP, transmitted address/data, and accumulated `ack_error`. Runtime SVA also proves that asserted drive-low controls produce observed low bus levels.

## Second-pass findings corrected

- Reserved-address bins that constraints could never hit were replaced with legal range bins and explicit illegal bins.
- Open-drain SCL/SDA assertions were added.
- Scoreboard no-traffic and shell `pipefail` guards were added.

## Xcelium boundary

No Xcelium runtime or functional-coverage percentage is claimed because the tool is not installed here. Complete UVM source elaboration passed. A licensed `make regress` run must finish with zero UVM errors/fatals, passing SVA, and the planned ACK/NACK coverage.
