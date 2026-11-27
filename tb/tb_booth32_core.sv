`timescale 1ns / 1ps

module tb_booth32_core;

    localparam int NUM_VECTORS = 2016;
    localparam time CLK_PERIOD = 10ns;

    logic        clk;
    logic        rst_n;
    logic        start;
    logic [31:0] multiplicand;
    logic [31:0] multiplier;
    logic [63:0] product;
    logic        done;

    // Memori vektor uji: [127:96] multiplicand, [95:64] multiplier, [63:0] expected
    logic [127:0] vectors [0:NUM_VECTORS-1];

    int errors = 0;
    int cycle_wait;
    logic [3:0] state_visited = 4'b0000;

    // Instansiasi DUT (Design Under Test)
    booth32_core dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .multiplicand (multiplicand),
        .multiplier   (multiplier),
        .product      (product),
        .done         (done)
    );

    // Pembangkit clock
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Pantau cakupan setiap state FSM
    always @(posedge clk) begin
        if (rst_n) begin
            state_visited[dut.state] <= 1'b1;
        end
    end

    // Proses pengujian utama
    initial begin
        $dumpfile("tb/booth32_core.vcd");
        $dumpvars(0, tb_booth32_core);

        $readmemh("tb/test_vectors.hex", vectors);

        rst_n        = 1'b0;
        start        = 1'b0;
        multiplicand = 32'd0;
        multiplier   = 32'd0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        for (int i = 0; i < NUM_VECTORS; i++) begin
            @(negedge clk);
            multiplicand = vectors[i][127:96];
            multiplier   = vectors[i][95:64];
            start        = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Tunggu hingga done == 1 (maksimal 50 siklus sebagai watchdog)
            cycle_wait = 0;
            while (done !== 1'b1 && cycle_wait < 50) begin
                @(posedge clk);
                cycle_wait++;
            end

            if (done !== 1'b1) begin
                $display("[ERROR] Timeout pada vektor %0d!", i);
                errors++;
            end else if (product !== vectors[i][63:0]) begin
                $display("[FAIL] Vektor %0d: %0d * %0d | Expected: %h, Got: %h",
                         i, $signed(multiplicand), $signed(multiplier),
                         vectors[i][63:0], product);
                errors++;
            end

            // Tunggu kembali ke IDLE
            @(posedge clk);
        end

        $display("========================================");
        $display("Total Vektor Diuji : %0d", NUM_VECTORS);
        $display("FSM State Coverage : %b (target: 1111)", state_visited);
        $display("Jumlah Error       : %0d", errors);
        if (errors == 0 && state_visited == 4'b1111) begin
            $display("STATUS             : PASS");
        end else begin
            $display("STATUS             : FAIL");
        end
        $display("========================================");
        $finish;
    end

endmodule
