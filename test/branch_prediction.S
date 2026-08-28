    .section .text
    .globl _start
    .option rvc
_start:
    # Resolve a load-dependent forward-taken branch while the wrong path has a
    # cross-word 32-bit fetch in progress.
    c.lw        x9, 0(x8)
    .option norvc
    beq         x9, x0, cross_fetch_target
    addi        x17, x0, 31
    .option rvc
cross_fetch_target:
    c.li        x8, 0

    # Forward not-taken: correctly predicted.
    .option norvc
    bne         x8, x0, forward_not_taken_bad
    .option rvc
    c.li        x18, 18

    # Forward taken: mispredicted and the sequential instruction is squashed.
    .option norvc
    beq         x8, x0, forward_taken_target
    .option rvc
forward_not_taken_bad:
    c.li        x20, 1
forward_taken_target:
    c.li        x20, 0

    # Backward taken twice, then backward not-taken on loop exit.
    c.li        x9, 3
backward_loop:
    c.addi      x9, -1
    .option norvc
    bne         x9, x0, backward_loop
    .option rvc

    # Direct jumps are always predicted taken. The first target instruction
    # consumes the link register to exercise EX link forwarding.
    .option norvc
    jal         x1, jal_target
    .option rvc
    c.li        x20, 2
jal_target:
    c.mv        x10, x1

    c.j         compressed_jump_target
    c.li        x20, 3
compressed_jump_target:
    c.jal       compressed_call
    c.li        x12, 12
    c.j         after_compressed_call
compressed_call:
    c.mv        x11, x1
    c.jr        x1

after_compressed_call:
    # Indirect jumps remain predicted not-taken and recover in EX.
    la          x13, indirect_call
    c.jalr      x13
    c.li        x14, 14
    c.j         finish_path
indirect_call:
    c.li        x15, 15
    c.jr        x1

finish_path:
    c.li        x16, 1
    sw          x16, 4(x0)

    .balign 4
