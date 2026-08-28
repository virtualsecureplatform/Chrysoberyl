    .section .text
    .globl _start
    .option rvc
_start:
    c.li        x8, 5
    c.addi      x8, -1
    c.li        x9, -3
    c.addi4spn  x10, x2, 16
    c.sw        x8, 0(x10)
    c.lw        x11, 0(x10)
    c.slli      x11, 2
    c.srli      x11, 1
    c.srai      x9, 1
    c.andi      x9, 7
    c.sub       x11, x8
    c.xor       x11, x9
    c.or        x11, x8
    c.and       x11, x8
    c.lui       x12, 1
    c.addi16sp  x2, 32
    c.swsp      x12, 0(x2)
    c.lwsp      x13, 0(x2)
    c.mv        x14, x13
    c.add       x14, x8
    c.li        x15, 0
    c.beqz      x15, 1f
    c.li        x20, 1
1:
    c.bnez      x8, 2f
    c.li        x20, 2
2:
    c.j         3f
    c.li        x20, 3
3:
    c.jal       compressed_subroutine
    c.li        x21, 21

    # Force an ordinary 32-bit instruction to straddle two ROM words.
    .balign 4
    c.nop
    .option norvc
    addi        x18, x0, 18
    .option rvc

    la          x17, jalr_subroutine
    c.jalr      x17
    c.li        x22, 22

    c.li        x10, 4
    c.sw        x8, 0(x10)
4:
    c.j         4b

compressed_subroutine:
    c.li        x16, 16
    c.jr        x1

jalr_subroutine:
    c.li        x19, 19
    c.jr        x1

    .balign 4
