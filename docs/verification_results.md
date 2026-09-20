# Verification results

Validation date: 2026-09-20

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint` completed with Verilator |
| Executable RTL smoke test | PASS | `I2C_SMOKE_PASS checks=3` |
| UVM source compile/elaboration lint | PASS | `sim/files.f`, assertions, slave model, and UVM package compiled against Accellera UVM core commit `78c0654` |

The smoke test decodes the actual open-drain serial bus and checks one ACKed transfer, one address NACK, and one data NACK, including START/STOP and payload recovery.

## Xcelium status

Cadence Xcelium was not installed in the validation environment, so no Xcelium runtime result is claimed. On a licensed Xcelium host, run `make uvm` for one seeded test or `make regress` for the five-seed regression. A passing run must finish with zero `UVM_ERROR` and zero `UVM_FATAL` messages.
