    .section .text
    .globl _start
    .option rvc
_start:
    # Adjacent compressed branches occupy distinct halfword-indexed entries.
    c.li        x8, 0
    c.beqz      x8, adjacent_branch
adjacent_branch:
    c.bnez      x8, pattern_setup

pattern_setup:
    li          x8, 0x1e3
    c.li        x9, 9
history_loop:
    c.mv        x10, x8
    c.andi      x10, 1
    .option norvc
history_branch:
    bne         x10, x0, history_taken
    .option rvc
    c.addi      x12, 1
    c.j         history_join
history_taken:
    c.addi      x13, 1
history_join:
    c.srli      x8, 1
    c.addi      x9, -1
    c.bnez      x9, history_loop

    # Direct jumps stay predicted taken; indirect jumps still recover in EX.
    la          x14, indirect_target
    c.jalr      x14
    c.li        x15, 15
    c.j         finish_path
indirect_target:
    c.li        x17, 17
    c.jr        x1

finish_path:
    c.li        x16, 1
    sw          x16, 4(x0)
    .balign 4
