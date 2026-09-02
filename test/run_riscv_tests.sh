#!/usr/bin/env sh
set -eu

RISCV_CC=${RISCV_CC:-clang}
RISCV_LD=${RISCV_LD:-ld.lld}
VERYL=${VERYL:-veryl}
BUILD_DIR=${RISCV_TEST_BUILD_DIR:-target/riscv-tests}
TEST_ROOT=thirdparties/riscv-tests

for tool in "$RISCV_CC" "$RISCV_LD" "$VERYL" verilator; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "missing required tool: $tool" >&2
        exit 2
    }
done

if [ ! -f "$TEST_ROOT/isa/rv32ui/add.S" ]; then
    echo "riscv-tests submodule is missing; run: git submodule update --init" >&2
    exit 2
fi

mkdir -p "$BUILD_DIR/bin"
"$VERYL" build
verilator -Wno-fatal --cc --exe --build --top-module chrysoberyl_Chrysoberyl \
    --Mdir "$BUILD_DIR/obj_dir" -o riscv_test_runner \
    "$(pwd)/target/chrysoberyl.sv" "$(pwd)/test/riscv-tests/sim_riscv_test.cpp"

case "$($RISCV_CC --version 2>/dev/null | head -1)" in
    *clang*) TARGET_FLAG=--target=riscv32 ;;
    *)       TARGET_FLAG= ;;
esac

TESTS="add addi and andi auipc beq bge bgeu blt bltu bne jal jalr lb lbu lh lhu lui lw or ori sb sh sll slli slt slti sltiu sltu sra srai srl srli sub sw xor xori"
ZBA_TESTS="sh1add sh2add sh3add"
ZBB_TESTS="andn clz cpop ctz max maxu min minu orc_b orn rev8 rol ror rori xnor"
PASS=0
FAIL=0

for name in $TESTS; do
    object="$BUILD_DIR/bin/rv32ui-$name.o"
    image="$BUILD_DIR/bin/rv32ui-$name.bin"
    "$RISCV_CC" $TARGET_FLAG -march=rv32i -mabi=ilp32 -x assembler-with-cpp \
        -Itest/riscv-tests -I"$TEST_ROOT/isa/macros/scalar" \
        -c "$TEST_ROOT/isa/rv32ui/$name.S" -o "$object"
    "$RISCV_LD" -m elf32lriscv -T test/riscv-tests/link.ld --oformat=binary \
        "$object" -o "$image"
    if "$BUILD_DIR/obj_dir/riscv_test_runner" "$image"; then
        echo "PASS: rv32ui-$name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: rv32ui-$name"
        FAIL=$((FAIL + 1))
    fi
done

for name in $ZBA_TESTS; do
    object="$BUILD_DIR/bin/rv32uzba-$name.o"
    image="$BUILD_DIR/bin/rv32uzba-$name.bin"
    "$RISCV_CC" $TARGET_FLAG -march=rv32i_zba -mabi=ilp32 -x assembler-with-cpp \
        -Itest/riscv-tests -I"$TEST_ROOT/isa/macros/scalar" \
        -c "$TEST_ROOT/isa/rv32uzba/$name.S" -o "$object"
    "$RISCV_LD" -m elf32lriscv -T test/riscv-tests/link.ld --oformat=binary \
        "$object" -o "$image"
    if "$BUILD_DIR/obj_dir/riscv_test_runner" "$image"; then
        echo "PASS: rv32uzba-$name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: rv32uzba-$name"
        FAIL=$((FAIL + 1))
    fi
done

for name in $ZBB_TESTS; do
    object="$BUILD_DIR/bin/rv32uzbb-$name.o"
    image="$BUILD_DIR/bin/rv32uzbb-$name.bin"
    "$RISCV_CC" $TARGET_FLAG -march=rv32i_zbb -mabi=ilp32 -x assembler-with-cpp \
        -Itest/riscv-tests -I"$TEST_ROOT/isa/macros/scalar" \
        -c "$TEST_ROOT/isa/rv32uzbb/$name.S" -o "$object"
    "$RISCV_LD" -m elf32lriscv -T test/riscv-tests/link.ld --oformat=binary \
        "$object" -o "$image"
    if "$BUILD_DIR/obj_dir/riscv_test_runner" "$image"; then
        echo "PASS: rv32uzbb-$name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: rv32uzbb-$name"
        FAIL=$((FAIL + 1))
    fi
done

name=rvc
object="$BUILD_DIR/bin/rv32uc-$name.o"
image="$BUILD_DIR/bin/rv32uc-$name.bin"
"$RISCV_CC" $TARGET_FLAG -march=rv32ic -mabi=ilp32 -x assembler-with-cpp \
    -Itest/riscv-tests -I"$TEST_ROOT/isa/macros/scalar" \
    -c "$TEST_ROOT/isa/rv32uc/$name.S" -o "$object"
"$RISCV_LD" -m elf32lriscv -T test/riscv-tests/link.ld --oformat=binary \
    "$object" -o "$image"
if "$BUILD_DIR/obj_dir/riscv_test_runner" "$image"; then
    echo "PASS: rv32uc-$name"
    PASS=$((PASS + 1))
else
    echo "FAIL: rv32uc-$name"
    FAIL=$((FAIL + 1))
fi

echo "riscv-tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
