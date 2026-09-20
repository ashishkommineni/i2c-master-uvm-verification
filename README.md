# I²C Master Write Controller and UVM Verification

A synthesizable single-byte I²C write master with true open-drain controls, ACK/NACK handling, clock-stretch awareness, a decoding slave model, UVM verification, SVA, coverage, and an executable smoke test.

## Transaction

```text
START → 7-bit address + W → ACK → 8-bit data → ACK → STOP
```

The master never drives a logic one; it either pulls SDA/SCL low or releases the line. Full scope and intentional limitations are in [the specification](docs/specification.md).

## Run

```bash
make uvm
make regress
make lint
make smoke
```

The smoke test decodes three real bus transactions: ACK success, address NACK, and data NACK. Passing output is `I2C_SMOKE_PASS checks=3`. The Xcelium UVM regression randomizes addresses, payloads, and negative ACK behavior.

See [verified results and tool scope](docs/verification_results.md) for the reproducible validation record.

## Engineering focus

I²C differs from push-pull protocols: a participant drives only low. A released line is high because of a pull-up, and the master must observe SCL after releasing it to tolerate clock stretching. The verification slave therefore responds on the shared serial line rather than shortcutting an internal DUT signal.

## License

MIT — see [LICENSE](LICENSE).
