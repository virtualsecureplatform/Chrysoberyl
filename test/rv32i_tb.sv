module rv32i_tb;
    logic clk = 0;
    logic rst = 1;
    logic [31:0] rom_data;
    logic [11:0] rom_addr;
    logic [31:0] ram_read_data;
    logic [9:0] ram_addr;
    logic [31:0] ram_write_data;
    logic [3:0] ram_we;
    logic finish;
    logic [31:0] x [32];
    logic [31:0] rom [0:4095];
    logic [31:0] ram [0:1023];

    chrysoberyl_Chrysoberyl dut (
        .i_clk(clk), .i_rst(rst), .i_rom_data(rom_data), .o_rom_addr(rom_addr),
        .i_ram_read_data(ram_read_data), .o_ram_addr(ram_addr),
        .o_ram_write_data(ram_write_data), .o_ram_we(ram_we), .o_finish(finish), .o_x(x)
    );

    function automatic [31:0] i_type(input [11:0] imm, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        i_type = {imm, rs1, funct3, rd, opcode};
    endfunction
    function automatic [31:0] r_type(input [6:0] funct7, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [4:0] rd);
        r_type = {funct7, rs2, rs1, funct3, rd, 7'b0110011};
    endfunction
    function automatic [31:0] s_type(input [11:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3);
        s_type = {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011};
    endfunction
    function automatic [31:0] b_type(input [12:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3);
        b_type = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], 7'b1100011};
    endfunction
    function automatic [31:0] j_type(input [20:0] imm, input [4:0] rd);
        j_type = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
    endfunction

    always #5 clk = ~clk;
    always_comb begin
        rom_data = rom[rom_addr];
        ram_read_data = ram[ram_addr[9:2]];
    end
    always_ff @(posedge clk) begin
        if (ram_we[0]) ram[ram_addr[9:2]][7:0]   <= ram_write_data[7:0];
        if (ram_we[1]) ram[ram_addr[9:2]][15:8]  <= ram_write_data[15:8];
        if (ram_we[2]) ram[ram_addr[9:2]][23:16] <= ram_write_data[23:16];
        if (ram_we[3]) ram[ram_addr[9:2]][31:24] <= ram_write_data[31:24];
    end

    initial begin
        for (int n = 0; n < 1024; n++) begin rom[n] = 32'h00000013; ram[n] = 0; end
        for (int n = 1024; n < 4096; n++) rom[n] = 32'h00000013;
        rom[ 0] = i_type(5,  0, 3'b000,  1, 7'b0010011); // addi x1, x0, 5
        rom[ 1] = i_type(-3, 0, 3'b000,  2, 7'b0010011); // addi x2, x0, -3
        rom[ 2] = r_type(0, 1, 1, 3'b000,  3);           // add x3, x1, x1
        rom[ 3] = r_type(7'b0100000, 2, 1, 3'b000, 4);   // sub x4, x1, x2
        rom[ 4] = r_type(0, 1, 2, 3'b010,  5);           // slt x5, x2, x1
        rom[ 5] = r_type(0, 1, 2, 3'b011,  6);           // sltu x6, x2, x1
        rom[ 6] = r_type(0, 4, 3, 3'b111,  7);           // and x7, x3, x4
        rom[ 7] = r_type(0, 4, 3, 3'b110,  8);           // or x8, x3, x4
        rom[ 8] = r_type(0, 4, 3, 3'b100,  9);           // xor x9, x3, x4
        rom[ 9] = r_type(0, 1, 1, 3'b001, 10);           // sll x10, x1, x1
        rom[10] = r_type(0, 1,10, 3'b101, 11);           // srl x11, x10, x1
        rom[11] = r_type(7'b0100000,1,2,3'b101,12);      // sra x12, x2, x1
        rom[12] = {20'h12345, 5'd13, 7'b0110111};        // lui x13, 0x12345
        rom[13] = {20'h00001, 5'd14, 7'b0010111};        // auipc x14, 0x1000
        rom[14] = s_type(0,  3, 0, 3'b010);               // sw x3, 0(x0)
        rom[15] = s_type(4,  4, 0, 3'b001);               // sh x4, 4(x0)
        rom[16] = s_type(6,  2, 0, 3'b000);               // sb x2, 6(x0)
        rom[17] = i_type(0,  0, 3'b010, 15, 7'b0000011); // lw x15, 0(x0)
        rom[18] = i_type(4,  0, 3'b001, 16, 7'b0000011); // lh x16, 4(x0)
        rom[19] = i_type(6,  0, 3'b000, 17, 7'b0000011); // lb x17, 6(x0)
        rom[20] = i_type(4,  0, 3'b101, 18, 7'b0000011); // lhu x18, 4(x0)
        rom[21] = i_type(6,  0, 3'b100, 19, 7'b0000011); // lbu x19, 6(x0)
        rom[22] = b_type(8,  1, 1, 3'b000);               // beq x1, x1, +8
        rom[23] = i_type(99, 0, 3'b000, 20, 7'b0010011); // skipped
        rom[24] = i_type(7,  0, 3'b000, 20, 7'b0010011);
        rom[25] = b_type(8,  1, 1, 3'b001);               // bne x1, x1, +8 (not taken)
        rom[26] = i_type(8,  0, 3'b000, 21, 7'b0010011);
        rom[27] = b_type(8,  1, 2, 3'b100);               // blt x2, x1, +8
        rom[28] = i_type(99, 0, 3'b000, 22, 7'b0010011); // skipped
        rom[29] = b_type(8,  2, 1, 3'b101);               // bge x1, x2, +8
        rom[30] = i_type(98, 0, 3'b000, 22, 7'b0010011); // skipped
        rom[31] = b_type(8,  2, 1, 3'b110);               // bltu x1, x2, +8
        rom[32] = i_type(97, 0, 3'b000, 23, 7'b0010011); // skipped
        rom[33] = b_type(8,  2, 1, 3'b111);               // bgeu x1, x2, +8 (not taken)
        rom[34] = i_type(9,  0, 3'b000, 23, 7'b0010011);
        rom[35] = j_type(8, 24);                          // jal x24, +8
        rom[36] = i_type(99, 0, 3'b000, 25, 7'b0010011); // skipped
        rom[37] = i_type(10, 0, 3'b000, 25, 7'b0010011);
        rom[38] = i_type(164,0, 3'b000, 26, 7'b0010011);
        rom[39] = i_type(1, 26, 3'b000, 27, 7'b1100111); // jalr x27, x26, 1
        rom[40] = i_type(99, 0, 3'b000, 28, 7'b0010011); // skipped
        rom[41] = i_type(11, 0, 3'b000, 28, 7'b0010011);
        rom[42] = s_type(4,  1, 0, 3'b010);               // finish store
        #2 rst = 0;
        #10 rst = 1;
        repeat (100) @(posedge clk);
        if (!finish || ram[0] !== 10 || ram[1] !== 5) $fatal(1, "memory/finish failure: finish=%b ram0=%h ram1=%h", finish, ram[0], ram[1]);
        if (dut.r_x[3] !== 10 || dut.r_x[4] !== 8 || dut.r_x[5] !== 1 || dut.r_x[6] !== 0 || dut.r_x[7] !== 8 || dut.r_x[8] !== 10 || dut.r_x[9] !== 2)
            $fatal(1, "integer ALU failure: x3=%h x4=%h x5=%h x6=%h x7=%h x8=%h x9=%h", dut.r_x[3], dut.r_x[4], dut.r_x[5], dut.r_x[6], dut.r_x[7], dut.r_x[8], dut.r_x[9]);
        if (dut.r_x[10] !== 160 || dut.r_x[11] !== 5 || dut.r_x[12] !== 32'hffff_ffff || dut.r_x[13] !== 32'h1234_5000 || dut.r_x[14] !== 32'h0000_1034) $fatal(1, "shift/U-type failure");
        if (dut.r_x[15] !== 10 || dut.r_x[16] !== 8 || dut.r_x[17] !== 32'hffff_fffd || dut.r_x[18] !== 8 || dut.r_x[19] !== 253) $fatal(1, "load failure");
        if (dut.r_x[20] !== 7 || dut.r_x[21] !== 8 || dut.r_x[22] !== 0 || dut.r_x[23] !== 9 || dut.r_x[24] !== 144 || dut.r_x[25] !== 10 || dut.r_x[27] !== 160 || dut.r_x[28] !== 11) $fatal(1, "control-flow failure");
        $display("PASS: full Chrysoberyl RV32I directed test");
        $finish;
    end
endmodule
