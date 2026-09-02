    .section .text
    .globl _start
    .option rvc
_start:
    # Exercise every C.SB offset with the two ends of the compact register set.
    li          x15, 64
    li          x8, 0x1234abcd
    c.sb        x8, 0(x15)
    c.sb        x8, 1(x15)
    c.sb        x8, 2(x15)
    c.sb        x8, 3(x15)

    # Exercise both C.SH offsets.
    li          x14, 80
    c.sh        x8, 0(x14)
    c.sh        x8, 2(x14)

    # Exercise every C.LBU offset.
    li          x13, 96
    c.lbu       x9, 0(x13)
    c.lbu       x10, 1(x13)
    c.lbu       x11, 2(x13)
    c.lbu       x12, 3(x13)
    mv          x16, x9
    mv          x17, x10
    mv          x18, x11
    mv          x19, x12

    # Check signed and unsigned halfword loads at both offsets.
    li          x12, 112
    c.lhu       x9, 0(x12)
    c.lh        x10, 0(x12)
    c.lhu       x11, 2(x12)
    c.lh        x12, 2(x12)
    mv          x20, x9
    mv          x21, x10
    mv          x22, x11
    mv          x23, x12

    li          x8, 0x1234ab80
    c.zext.b    x8
    li          x15, 0x12345678
    c.not       x15

    # Zbb enables the compressed sign/zero-extension instructions.
    li          x9, 0x11111181
    li          x10, 0x22228001
    li          x11, 0x33338001
    li          x12, 7
    li          x13, 9
    c.sext.b    x9
    c.zext.h    x10
    c.sext.h    x11

    # C.MUL still requires M or Zmmul and remains an illegal bubble.
    .2byte      0x9e55      # c.mul x12, x13

    # C.SH requires encoding bit 6 to be zero. This reserved variant must not store.
    .2byte      0x8f40

    li          x5, 1
    sw          x5, 4(x0)
1:
    c.j         1b

    .balign 4
