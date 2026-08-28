module smoke_tb;
    logic clk = 0;
    logic rst = 1;
    logic [31:0] rom_data;
    logic [11:0] rom_addr;
    logic [31:0] ram_read_data = 0;
    logic [9:0] ram_addr;
    logic [31:0] ram_write_data;
    logic [3:0] ram_we;
    logic finish;
    logic [31:0] x [32];
    logic [31:0] ram [1024];

    chrysoberyl_Chrysoberyl dut (
        .i_clk(clk), .i_rst(rst), .i_rom_data(rom_data), .o_rom_addr(rom_addr),
        .i_ram_read_data(ram_read_data), .o_ram_addr(ram_addr),
        .o_ram_write_data(ram_write_data), .o_ram_we(ram_we), .o_finish(finish), .o_x(x)
    );

    always #5 clk = ~clk;
    always_comb begin
        case (rom_addr)
            0: rom_data = 32'h0050_0093; // addi x1, x0, 5
            1: rom_data = 32'h0070_8113; // addi x2, x1, 7
            2: rom_data = 32'h0020_2223; // sw   x2, 4(x0)
            default: rom_data = 32'h0000_0013;
        endcase
        ram_read_data = ram[ram_addr];
    end
    always_ff @(posedge clk) begin
        if (ram_we[0]) ram[ram_addr][7:0]   <= ram_write_data[7:0];
        if (ram_we[1]) ram[ram_addr][15:8]  <= ram_write_data[15:8];
        if (ram_we[2]) ram[ram_addr][23:16] <= ram_write_data[23:16];
        if (ram_we[3]) ram[ram_addr][31:24] <= ram_write_data[31:24];
    end

    initial begin
        for (int i = 0; i < 1024; i++) ram[i] = 0;
        #2 rst = 0;
        #10 rst = 1;
        repeat (12) @(posedge clk);
        if (!finish || ram[4] !== 12 || dut.r_x[1] !== 5 || dut.r_x[2] !== 12) $fatal(1, "RV32I smoke test failed: finish=%b ram[4]=%h x1=%h x2=%h", finish, ram[4], dut.r_x[1], dut.r_x[2]);
        $display("PASS: Chrysoberyl RV32I smoke test");
        $finish;
    end
endmodule
