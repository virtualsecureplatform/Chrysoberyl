    .section .text
    .globl _start
    .option norvc
_start:
    li          x1, 3
    li          x2, 7
    sh1add      x3, x1, x2
    sh2add      x4, x1, x2
    sh3add      x5, x1, x2

    # Verify 32-bit wraparound after each fixed shift.
    li          x1, 0x80000001
    li          x2, -1
    sh1add      x6, x1, x2
    sh2add      x7, x1, x2
    sh3add      x8, x1, x2

    # Zero operands.
    li          x1, 0
    li          x2, 123
    sh1add      x9, x1, x2
    li          x1, 5
    li          x2, 0
    sh3add      x10, x1, x2

    # Source/destination overlap and adjacent EX/MEM forwarding.
    li          x11, 3
    li          x12, 7
    sh1add      x11, x11, x12
    sh2add      x12, x11, x12
    sh3add      x13, x11, x12
    sh1add      x14, x13, x13

    sh3add      x0, x1, x2
    li          x31, 1
    sw          x31, 4(x0)
1:
    jal         x0, 1b

    .balign 4
