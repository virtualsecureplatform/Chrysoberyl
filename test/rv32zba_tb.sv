module rv32zba_tb;
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
        for (int n = 0; n < 4096; n++) rom[n] = 32'h00000013;
        for (int n = 0; n < 1024; n++) ram[n] = 0;
        $readmemh("test/rv32zba.hex", rom, 0, 26);
        #2 rst = 0;
        #10 rst = 1;
        wait (finish);
        repeat (2) @(posedge clk);

        if (dut.r_x[3] !== 13 || dut.r_x[4] !== 19 || dut.r_x[5] !== 31)
            $fatal(1, "Zba fixed-shift addition failure");
        if (dut.r_x[6] !== 1 || dut.r_x[7] !== 3 || dut.r_x[8] !== 7)
            $fatal(1, "Zba wraparound failure");
        if (dut.r_x[9] !== 123 || dut.r_x[10] !== 40)
            $fatal(1, "Zba zero-operand failure");
        if (dut.r_x[11] !== 13 || dut.r_x[12] !== 59
            || dut.r_x[13] !== 163 || dut.r_x[14] !== 489)
            $fatal(1, "Zba overlap or forwarding failure");
        if (dut.r_x[0] !== 0)
            $fatal(1, "Zba write unexpectedly changed x0");
        $display("PASS: full Chrysoberyl RV32 Zba directed test");
        $finish;
    end

    initial begin
        repeat (150) @(posedge clk);
        $fatal(1, "Zba test timed out");
    end
endmodule
