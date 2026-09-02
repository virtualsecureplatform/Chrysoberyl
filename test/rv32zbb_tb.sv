module rv32zbb_tb;
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
        ram_read_data = ram[ram_addr];
    end
    always_ff @(posedge clk) begin
        if (ram_we[0]) ram[ram_addr][7:0]   <= ram_write_data[7:0];
        if (ram_we[1]) ram[ram_addr][15:8]  <= ram_write_data[15:8];
        if (ram_we[2]) ram[ram_addr][23:16] <= ram_write_data[23:16];
        if (ram_we[3]) ram[ram_addr][31:24] <= ram_write_data[31:24];
    end

    initial begin
        for (int n = 0; n < 4096; n++) rom[n] = 32'h00000013;
        for (int n = 0; n < 1024; n++) ram[n] = 0;
        $readmemh("test/rv32zbb.hex", rom, 0, 50);
        #2 rst = 0;
        #10 rst = 1;
        wait (finish);
        repeat (2) @(posedge clk);

        if (dut.r_x[3] !== 32'h0f000f00 || dut.r_x[4] !== 32'hff0fff0f
            || dut.r_x[5] !== 32'hf00ff00f)
            $fatal(1, "Zbb logical-with-negate failure");
        if (dut.r_x[6] !== 32 || dut.r_x[7] !== 32 || dut.r_x[8] !== 16
            || dut.r_x[23] !== 31 || dut.r_x[24] !== 31 || dut.r_x[25] !== 32)
            $fatal(1, "Zbb count failure");
        if (dut.r_x[9] !== 32'h80000000 || dut.r_x[10] !== 7
            || dut.r_x[11] !== 7 || dut.r_x[12] !== 32'h80000000)
            $fatal(1, "Zbb min/max failure");
        if (dut.r_x[13] !== 32'hffffff81 || dut.r_x[14] !== 32'hffff8081
            || dut.r_x[15] !== 32'h00008081)
            $fatal(1, "Zbb extension failure");
        if (dut.r_x[16] !== 3 || dut.r_x[17] !== 32'hc0000000
            || dut.r_x[18] !== 3 || dut.r_x[21] !== 32'h80000001
            || dut.r_x[22] !== 32'h80000001)
            $fatal(1, "Zbb rotate or forwarding failure");
        if (dut.r_x[19] !== 32'h00ff00ff || dut.r_x[20] !== 32'h78563412)
            $fatal(1, "Zbb byte operation failure");
        if (dut.r_x[0] !== 0)
            $fatal(1, "Zbb write unexpectedly changed x0");
        $display("PASS: full Chrysoberyl RV32 Zbb directed test");
        $finish;
    end

    initial begin
        repeat (200) @(posedge clk);
        $fatal(1, "Zbb test timed out");
    end
endmodule
