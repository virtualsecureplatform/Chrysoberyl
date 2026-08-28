# Chrysoberyl

Chrysoberyl is a Veryl port of [Alexandrite](../Alexandrite), a small in-order
RV32I CPU. It retains Alexandrite's instruction ROM and byte-enable RAM
interfaces (including its byte-addressed RAM address port), exposes all 32
integer registers for simulation, and raises
`o_finish` after a non-zero store to address `0x4`.

The current implementation supports the Alexandrite RV32I subset: integer
arithmetic, branches, jumps, loads, stores, `LUI`, and `AUIPC`.  CSR and
system instructions remain intentionally outside Alexandrite's scope.

## Build

Install [Veryl](https://veryl-lang.org/) and run:

```sh
veryl check
veryl build
```

Generated SystemVerilog is placed in `target/`.

Run the included smoke test plus a directed RV32I instruction test with:

```sh
sh test/run_smoke.sh
```
