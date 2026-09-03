module history_prediction_tb;
    localparam logic [31:0] HISTORY_BRANCH_PC = 32'h0000_0010;
    localparam integer HISTORY_BRANCH_INDEX = HISTORY_BRANCH_PC[6:1];
    localparam integer FIRST_C_BRANCH_INDEX = 1;
    localparam integer SECOND_C_BRANCH_INDEX = 2;

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
    integer history_observations = 0;
    integer history_redirects = 0;
    integer direct_redirects = 0;
    integer indirect_redirects = 0;

    chrysoberyl_Chrysoberyl #(.USE_HISTORY_PREDICTION(1'b1)) dut (
        .i_clk(clk), .i_rst(rst), .i_rom_data(rom_data), .o_rom_addr(rom_addr),
        .i_ram_read_data(ram_read_data), .o_ram_addr(ram_addr),
        .o_ram_write_data(ram_write_data), .o_ram_we(ram_we), .o_finish(finish), .o_x(x)
    );

    function automatic expected_prediction(input integer observation);
        case (observation)
            0: expected_prediction = 0;
            1, 2, 3: expected_prediction = 1;
            4, 5, 6: expected_prediction = 0;
            default: expected_prediction = 1;
        endcase
    endfunction

    function automatic expected_outcome(input integer observation);
        case (observation)
            0, 1, 5, 6, 7, 8: expected_outcome = 1;
            default: expected_outcome = 0;
        endcase
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

        if (rst && dut.w_ex_control) begin
            if (dut.r_ex_branch != 0 && dut.r_ex_pc4 == HISTORY_BRANCH_PC + 4) begin
                if (dut.r_ex_pred_taken !== expected_prediction(history_observations))
                    $fatal(1, "history prediction %0d was %b, expected %b", history_observations, dut.r_ex_pred_taken, expected_prediction(history_observations));
                if (dut.w_ex_branch_ok !== expected_outcome(history_observations))
                    $fatal(1, "history outcome %0d was %b, expected %b", history_observations, dut.w_ex_branch_ok, expected_outcome(history_observations));
                history_observations <= history_observations + 1;
                if (dut.w_ex_redirect) history_redirects <= history_redirects + 1;
            end
            if (dut.r_ex_wb_sel == 2'd2 && dut.r_ex_pred_taken && dut.w_ex_redirect)
                direct_redirects <= direct_redirects + 1;
            if (dut.r_ex_wb_sel == 2'd2 && !dut.r_ex_pred_taken && dut.w_ex_redirect)
                indirect_redirects <= indirect_redirects + 1;
        end
    end

    initial begin
        for (int n = 0; n < 1024; n++) begin rom[n] = 32'h00000013; ram[n] = 0; end
        for (int n = 1024; n < 4096; n++) rom[n] = 32'h00000013;
        $readmemh("test/history_prediction.hex", rom, 0, 13);
        #2 rst = 0;
        #8;
        if (dut.g_history_prediction.r_bht_valid[HISTORY_BRANCH_INDEX] !== 0)
            $fatal(1, "history valid bits were not cleared by reset");
        #2 rst = 1;
        wait (finish);
        repeat (2) @(posedge clk);

        if (history_observations !== 9 || history_redirects !== 5)
            $fatal(1, "history sequence failure: observations=%0d redirects=%0d", history_observations, history_redirects);
        if (!dut.g_history_prediction.r_bht_valid[HISTORY_BRANCH_INDEX]
            || dut.g_history_prediction.r_bht_counter[HISTORY_BRANCH_INDEX] !== 2'b11)
            $fatal(1, "history counter did not saturate strongly taken");
        if (!dut.g_history_prediction.r_bht_valid[FIRST_C_BRANCH_INDEX]
            || !dut.g_history_prediction.r_bht_valid[SECOND_C_BRANCH_INDEX])
            $fatal(1, "adjacent RV32C branches did not train distinct entries");
        if (direct_redirects !== 0 || indirect_redirects !== 2)
            $fatal(1, "jump policy changed: direct_redirects=%0d indirect_redirects=%0d", direct_redirects, indirect_redirects);
        if (dut.r_x[12] !== 3 || dut.r_x[13] !== 6 || dut.r_x[15] !== 15 || dut.r_x[17] !== 17)
            $fatal(1, "history prediction program execution failure");

        $display("PASS: Chrysoberyl local-history prediction test (9 outcomes, 5 redirects, final counter=11)");
        $finish;
    end

    initial begin
        repeat (150) @(posedge clk);
        $fatal(1, "history prediction test timed out");
    end
endmodule
