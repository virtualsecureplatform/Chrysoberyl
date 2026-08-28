module branch_prediction_tb;
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
    integer controls = 0;
    integer predicted_taken = 0;
    integer redirects = 0;
    integer direct_redirects = 0;
    integer cross_fetch_redirects = 0;
    integer cycles = 0;

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
        if (rst) begin
            cycles <= cycles + 1;
            if (dut.w_ex_control) begin
                controls <= controls + 1;
                if (dut.r_ex_pred_taken) predicted_taken <= predicted_taken + 1;
                if (dut.w_ex_redirect) redirects <= redirects + 1;
                if (dut.r_ex_pred_taken && dut.r_ex_wb_sel == 2'd2 && dut.w_ex_redirect)
                    direct_redirects <= direct_redirects + 1;
                if (dut.w_ex_redirect && dut.r_fetch_cross)
                    cross_fetch_redirects <= cross_fetch_redirects + 1;
            end
        end
    end

    initial begin
        for (int n = 0; n < 1024; n++) begin rom[n] = 32'h00000013; ram[n] = 0; end
        for (int n = 1024; n < 4096; n++) rom[n] = 32'h00000013;
        $readmemh("test/branch_prediction.hex", rom, 0, 19);
        #2 rst = 0;
        #10 rst = 1;
        wait (finish);
        repeat (2) @(posedge clk);
        if (dut.r_x[9] !== 0 || dut.r_x[17] !== 0 || dut.r_x[18] !== 18 || dut.r_x[20] !== 0)
            $fatal(1, "conditional prediction or wrong-path squash failure");
        if (dut.r_x[10] !== 32'h26 || dut.r_x[11] !== 32'h30)
            $fatal(1, "predicted direct-jump link/forwarding failure: x10=%h x11=%h", dut.r_x[10], dut.r_x[11]);
        if (dut.r_x[12] !== 12 || dut.r_x[14] !== 14 || dut.r_x[15] !== 15)
            $fatal(1, "direct/indirect jump execution failure");
        if (controls !== 14 || predicted_taken !== 8 || redirects !== 6 || direct_redirects !== 0 || cross_fetch_redirects !== 1)
            $fatal(1, "prediction accounting failure: controls=%0d predicted=%0d redirects=%0d direct_redirects=%0d cross_redirects=%0d", controls, predicted_taken, redirects, direct_redirects, cross_fetch_redirects);
        if (cycles > 55)
            $fatal(1, "prediction pipeline took too many cycles: %0d", cycles);
        $display("PASS: Chrysoberyl static branch prediction test (%0d controls, %0d redirects, %0d cycles)", controls, redirects, cycles);
        $finish;
    end

    initial begin
        repeat (100) @(posedge clk);
        $fatal(1, "branch prediction test timed out");
    end
endmodule
