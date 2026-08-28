# Chrysoberyl

Chrysoberyl is a Veryl port of [Alexandrite](../Alexandrite), a small in-order
RV32IC CPU. It retains Alexandrite's instruction ROM and byte-enable RAM
interfaces (including its byte-addressed RAM address port), exposes all 32
integer registers for simulation, and raises
`o_finish` after a non-zero store to address `0x4`.

The current implementation supports the Alexandrite RV32I subset plus the
RV32C compressed-instruction extension, including mixed 16/32-bit streams and
32-bit instructions that cross a ROM-word boundary. Integer arithmetic,
branches, jumps, loads, stores, `LUI`, and `AUIPC` are supported. CSR and
system instructions remain intentionally outside Alexandrite's scope.

Control flow uses a static fetch-stage predictor: backward conditional branches
are predicted taken, forward conditional branches are predicted not taken, and
direct jumps are predicted taken. Indirect jumps continue to resolve in the
execute stage.

## Build

Install [Veryl](https://veryl-lang.org/) and run:

```sh
veryl check
veryl build
```

Generated SystemVerilog is placed in `target/`.

Run the included smoke test plus directed RV32I and RV32C instruction tests with:

```sh
sh test/run_smoke.sh
```
