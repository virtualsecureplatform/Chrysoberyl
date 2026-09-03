module rv32zcb_tb;
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
        for (int n = 0; n < 1024; n++) ram[n] = 32'ha5a5a5a5;
        ram[24] = 32'h80808080;
        ram[28] = 32'h80018001;
        $readmemh("test/rv32zcb.hex", rom, 0, 31);
        #2 rst = 0;
        #10 rst = 1;
        wait (finish);
        repeat (2) @(posedge clk);

        if (ram[16] !== 32'hcdcdcdcd)
            $fatal(1, "Zcb byte-store offset or byte-enable failure");
        if (ram[20] !== 32'habcdabcd)
            $fatal(1, "Zcb halfword-store offset or byte-enable failure");
        if (dut.r_x[16] !== 32'h00000080 || dut.r_x[17] !== 32'h00000080
            || dut.r_x[18] !== 32'h00000080 || dut.r_x[19] !== 32'h00000080)
            $fatal(1, "Zcb byte-load offset or zero-extension failure");
        if (dut.r_x[20] !== 32'h00008001 || dut.r_x[21] !== 32'hffff8001
            || dut.r_x[22] !== 32'h00008001 || dut.r_x[23] !== 32'hffff8001)
            $fatal(1, "Zcb halfword-load offset or extension failure");
        if (dut.r_x[8] !== 32'h00000080 || dut.r_x[15] !== 32'hedcba987)
            $fatal(1, "Zcb unary operation failure: x8=%h x15=%h", dut.r_x[8], dut.r_x[15]);
        if (dut.r_x[9] !== 32'hffffff81 || dut.r_x[10] !== 32'h00008001
            || dut.r_x[11] !== 32'hffff8001)
            $fatal(1, "Zbb-dependent Zcb extension failure");
        $display("PASS: Chrysoberyl RV32IC_Zbb_Zcb directed test");
        $finish;
    end

    initial begin
        repeat (150) @(posedge clk);
        $fatal(1, "Zcb test timed out");
    end
endmodule
