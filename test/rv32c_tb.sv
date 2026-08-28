module rv32c_tb;
    logic clk = 0;
    logic rst = 1;
    logic [31:0] rom_data;
    logic [9:0] rom_addr;
    logic [31:0] ram_read_data;
    logic [9:0] ram_addr;
    logic [31:0] ram_write_data;
    logic [3:0] ram_we;
    logic finish;
    logic [31:0] x [32];
    logic [31:0] rom [0:1023];
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
        for (int n = 0; n < 1024; n++) begin rom[n] = 32'h00000013; ram[n] = 0; end
        $readmemh("test/rv32c.hex", rom, 0, 22);
        #2 rst = 0;
        #10 rst = 1;
        repeat (100) @(posedge clk);
        if (!finish || ram[4] !== 4 || ram[16] !== 4 || ram[32] !== 32'h1000)
            $fatal(1, "RV32C memory failure: finish=%b ram4=%h ram16=%h ram32=%h", finish, ram[4], ram[16], ram[32]);
        if (dut.r_x[8] !== 4 || dut.r_x[9] !== 6 || dut.r_x[10] !== 4 || dut.r_x[11] !== 4)
            $fatal(1, "RV32C compact-register ALU/load/store failure: x8=%h x9=%h x10=%h x11=%h", dut.r_x[8], dut.r_x[9], dut.r_x[10], dut.r_x[11]);
        if (dut.r_x[2] !== 32 || dut.r_x[12] !== 32'h1000 || dut.r_x[13] !== 32'h1000 || dut.r_x[14] !== 32'h1004)
            $fatal(1, "RV32C stack/LUI/register operation failure");
        if (dut.r_x[16] !== 16 || dut.r_x[18] !== 18 || dut.r_x[19] !== 19 || dut.r_x[20] !== 0 || dut.r_x[21] !== 21 || dut.r_x[22] !== 22)
            $fatal(1, "RV32C control-flow or mixed-width fetch failure");
        $display("PASS: full Chrysoberyl RV32C directed test");
        $finish;
    end
endmodule
