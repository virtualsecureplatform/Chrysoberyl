    .section .text
    .globl _start
    .option norvc
_start:
    li          x1, 0x0f0f0f0f
    li          x2, 0x00ff00ff
    andn        x3, x1, x2
    orn         x4, x1, x2
    xnor        x5, x1, x2

    li          x1, 0
    clz         x6, x1
    ctz         x7, x1
    li          x1, 0xf0f00f0f
    cpop        x8, x1

    li          x1, 0x80000000
    li          x2, 7
    min         x9, x1, x2
    minu        x10, x1, x2
    max         x11, x1, x2
    maxu        x12, x1, x2

    li          x1, 0x12348081
    sext.b      x13, x1
    sext.h      x14, x1
    zext.h      x15, x1

    li          x1, 0x80000001
    li          x2, 1
    rol         x16, x1, x2
    ror         x17, x1, x2
    rori        x18, x1, 31

    li          x1, 0x00010080
    orc.b       x19, x1
    li          x1, 0x12345678
    rev8        x20, x1

    # Source/destination overlap and adjacent-result forwarding.
    li          x21, 0x80000001
    rol         x21, x21, x2
    ror         x21, x21, x2
    rori        x22, x21, 0

    # Additional count boundaries and a discarded x0 result.
    li          x1, 1
    clz         x23, x1
    li          x1, 0x80000000
    ctz         x24, x1
    li          x1, -1
    cpop        x25, x1
    cpop        x0, x1

    li          x31, 1
    sw          x31, 4(x0)
1:
    jal         x0, 1b

    .balign 4
