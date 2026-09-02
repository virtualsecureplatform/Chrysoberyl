# Chrysoberyl

Chrysoberyl is a Veryl port of [Alexandrite](../Alexandrite), a small in-order
RV32IC_Zba_Zbb_Zcb CPU. It retains Alexandrite's instruction ROM and byte-enable RAM
interfaces (including its byte-addressed RAM address port), exposes all 32
integer registers for simulation, and raises
`o_finish` after a non-zero store to address `0x4`.

The current implementation supports the Alexandrite RV32I subset plus the
RV32C compressed-instruction extension, including mixed 16/32-bit streams and
32-bit instructions that cross a ROM-word boundary. Integer arithmetic,
branches, jumps, loads, stores, `LUI`, and `AUIPC` are supported. CSR and
system instructions remain intentionally outside Alexandrite's scope.

The RV32 Zba address-generation extension provides one-cycle shift-and-add
instructions for array and structure indexing. The Zbb basic bit-manipulation
extension provides logical-with-negate,
count, min/max, sign/zero-extension, rotate, OR-combine, and byte-reverse
instructions. All Zbb operations execute in one cycle.

For the current RV32IC_Zbb configuration, the Zcb code-size extension adds
`c.lbu`, `c.lhu`, `c.lh`, `c.sb`, `c.sh`, `c.zext.b`, and `c.not`. The
Zbb-dependent `c.sext.b`, `c.zext.h`, and `c.sext.h` instructions are also
supported. `c.mul` requires M or Zmmul, so that encoding remains illegal.

The instruction address space defaults to 16 KiB. Set the elaboration-time
`ROM_SIZE_BYTES` module parameter to another power-of-two byte size when a
different ROM capacity is required; the PC and word-address output widths are
derived from that value.

Control flow uses a static fetch-stage predictor: backward conditional branches
are predicted taken, forward conditional branches are predicted not taken, and
direct jumps are predicted taken. Indirect jumps continue to resolve in the
execute stage.

Set the `USE_HISTORY_PREDICTION` module parameter to `true` to replace BTFNT
conditional-branch decisions with a 64-entry local history table. Each valid
entry is a two-bit saturating counter indexed by halfword PC bits `[6:1]`;
untrained entries fall back to BTFNT. The table is tagless, so aliased branch
PCs intentionally share history. Direct and indirect jump policies are
unchanged.

## Build

Install [Veryl](https://veryl-lang.org/) and run:

```sh
veryl check
veryl build
```

Generated SystemVerilog is placed in `target/`.

Run the included smoke test plus directed RV32I, Zba, Zbb, RV32C, and Zcb instruction tests with:

```sh
sh test/run_smoke.sh
```

## Upstream RISC-V ISA tests

The latest [riscv-tests](https://github.com/riscv-software-src/riscv-tests)
repository is pinned as a Git submodule. Initialize it after cloning with:

```sh
git submodule update --init
```

Run the 37 unprivileged `rv32ui` tests, three upstream `rv32uzba` tests, 15
upstream `rv32uzbb` tests, and the upstream `rv32uc` compressed-instruction
test with:

```sh
sh test/run_riscv_tests.sh
```

The runner builds the current Veryl source with Verilator, compiles each test
using Clang's RISC-V target, loads a flat ROM/RAM image, and observes the
standard `tohost` result. Set `VERYL`, `RISCV_CC`, or `RISCV_LD` to override the
corresponding tools. Chrysoberyl provides a 16 KiB instruction address space so
the complete upstream `rv32uc` image fits without modification.
