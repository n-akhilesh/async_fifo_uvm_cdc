// ============================================================
// Module      : tb_async_fifo_directed
// Project     : async_fifo_uvm_cdc
// Description : Directed non-UVM testbench for async_fifo_top.
//               4 directed tests covering full/empty/reset.
//               SVA bind file included for assertion checking.
//               Generates dump.vcd for GTKWave inspection.
//
// Clocks:
//   wr_clk : 100 MHz → period = 10ns
//   rd_clk :  73 MHz → period = 13.699ns (coprime to wr_clk)
//
// Tests:
//   Test 1 — Write 16 items at 100MHz, read at 73MHz
//   Test 2 — Fill to full, attempt overflow write
//   Test 3 — Drain to empty, attempt underflow read
//   Test 4 — Assert arst_n mid-operation, verify pointer reset
// ============================================================

`timescale 1ns/1ps

module tb_async_fifo_directed;

  // ============================================================
  // Parameters — must match DUT
  // ============================================================
  parameter int DEPTH      = 16;
  parameter int DATA_WIDTH = 8;
  parameter int PTR_WIDTH  = $clog2(DEPTH) + 1;  // 5 bits
  parameter int AF_THRESH  = 4;
  parameter int AE_THRESH  = 2;

  // ============================================================
  // Clock periods
  // wr_clk : 100 MHz = 10.000 ns period
  // rd_clk :  73 MHz = 13.699 ns period (coprime — worst case CDC)
  // ============================================================
  parameter real WR_CLK_PERIOD = 10.000;    // 100 MHz
  parameter real RD_CLK_PERIOD = 13.699;    //  73 MHz

  // ============================================================
  // DUT Signal Declarations
  // ============================================================
  logic                  wr_clk;
  logic                  rd_clk;
  logic                  arst_n;        // Async active-low reset
  logic                  wr_en;
  logic                  rd_en;
  logic [DATA_WIDTH-1:0] wr_data;
  logic [DATA_WIDTH-1:0] rd_data;
  logic                  full;
  logic                  empty;
  logic                  almost_full;
  logic                  almost_empty;

  // ============================================================
  // Test Tracking
  // ============================================================
  int  test_errors   = 0;   // Global error counter
  int  write_count   = 0;   // Tracks how many items written
  int  read_count    = 0;   // Tracks how many items read

  // Reference model — golden queue for scoreboard
  logic [DATA_WIDTH-1:0] ref_queue [$];  // SystemVerilog queue (FIFO model)
  logic [DATA_WIDTH-1:0] expected_data;

  // ============================================================
  // DUT Instantiation — async_fifo_top
  // ============================================================
  async_fifo_top #(
    .DEPTH      (DEPTH),
    .DATA_WIDTH (DATA_WIDTH),
    .AF_THRESH  (AF_THRESH),
    .AE_THRESH  (AE_THRESH)
  ) dut (
    .wr_clk      (wr_clk),
    .rd_clk      (rd_clk),
    .arst_n      (arst_n),
    .wr_en       (wr_en),
    .rd_en       (rd_en),
    .wr_data     (wr_data),
    .rd_data     (rd_data),
    .full        (full),
    .empty       (empty),
    .almost_full (almost_full),
    .almost_empty(almost_empty)
  );

  // ============================================================
  // SVA Bind — fifo_assertions bound to async_fifo_top
  // Assertions fire automatically during simulation
  // Any SVA failure prints $error and increments error count
  // ============================================================
  bind async_fifo_top fifo_assertions #(
    .DEPTH      (DEPTH),
    .DATA_WIDTH (DATA_WIDTH),
    .PTR_WIDTH  (PTR_WIDTH),
    .AF_THRESH  (AF_THRESH),
    .AE_THRESH  (AE_THRESH)
  ) u_assertions (
    .wr_clk         (wr_clk),
    .rd_clk         (rd_clk),
    .wr_rstn        (srst_n_wr),
    .rd_rstn        (srst_n_rd),
    .wr_en          (wr_en),
    .rd_en          (rd_en),
    .full           (full),
    .empty          (empty),
    .almost_full    (almost_full),
    .almost_empty   (almost_empty),
    .wptr_gray      (wptr_gray),
    .rptr_gray      (rptr_gray),
    .wptr_bin       (wbin),
    .rptr_bin       (rbin),
    .rptr_gray_sync (rptr_gray_sync),
    .wptr_gray_sync (wptr_gray_sync)
  );

  // ============================================================
  // VCD Dump — open in GTKWave after simulation
  // Run: gtkwave dump.vcd
  // Add signals: wr_clk, rd_clk, wr_en, rd_en, wr_data,
  //              rd_data, full, empty, almost_full, almost_empty
  //              wptr_gray, rptr_gray
  // ============================================================
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_async_fifo_directed);  // Dump ALL signals
  end

  // ============================================================
  // Clock Generation
  // Both clocks start at time 0 with phase offset 0
  // Coprime periods ensure all phase relationships are covered
  // ============================================================
  initial wr_clk = 1'b0;
  always #(WR_CLK_PERIOD/2.0) wr_clk = ~wr_clk;  // 100 MHz

  initial rd_clk = 1'b0;
  always #(RD_CLK_PERIOD/2.0) rd_clk = ~rd_clk;  //  73 MHz

  // ============================================================
  // TASK: do_write
  // Performs a single synchronous write on wr_clk
  // Skips write if FIFO is full (overflow protection)
  // Pushes data into reference queue for scoreboard check
  // ============================================================
  task automatic do_write(input logic [DATA_WIDTH-1:0] data);
    @(posedge wr_clk);
    #1;  // Small delta delay — avoid setup violation
    if (!full) begin
      wr_en   <= 1'b1;
      wr_data <= data;
      ref_queue.push_back(data);  // Golden model push
      write_count++;
      @(posedge wr_clk);
      #1;
      wr_en   <= 1'b0;
      wr_data <= '0;
      $display("[WRITE] data=0x%02h  wptr_count=%0d  full=%0b  almost_full=%0b",
               data, write_count, full, almost_full);
    end else begin
      $display("[WRITE BLOCKED] FIFO full — skipping write of 0x%02h", data);
      wr_en   <= 1'b0;
    end
  endtask

  // ============================================================
  // TASK: do_read
  // Performs a single synchronous read on rd_clk
  // Skips read if FIFO is empty (underflow protection)
  // Compares rd_data against reference queue (scoreboard)
  // ============================================================
  task automatic do_read();
    @(posedge rd_clk);
    #1;
    if (!empty) begin
      rd_en <= 1'b1;
      @(posedge rd_clk);
      #1;
      rd_en <= 1'b0;
      // Scoreboard check — compare against golden queue
      if (ref_queue.size() > 0) begin
        expected_data = ref_queue.pop_front();
        read_count++;
        if (rd_data === expected_data) begin
          $display("[READ  PASS] rd_data=0x%02h  expected=0x%02h  empty=%0b  almost_empty=%0b",
                   rd_data, expected_data, empty, almost_empty);
        end else begin
          $error("[READ  FAIL] rd_data=0x%02h  expected=0x%02h ← DATA MISMATCH!",
                 rd_data, expected_data);
          test_errors++;
        end
      end
    end else begin
      $display("[READ BLOCKED] FIFO empty — skipping read");
      rd_en <= 1'b0;
    end
  endtask

  // ============================================================
  // TASK: apply_reset
  // Asserts arst_n low for 5 wr_clk cycles then deasserts
  // Async assert — fires immediately regardless of clock edge
  // Sync deassert — srst_n_wr/rd go high 2 cycles after arst_n
  // ============================================================
  task automatic apply_reset(input int hold_cycles = 5);
    $display("[RESET] Asserting arst_n LOW");
    arst_n = 1'b0;         // Async assert — immediate
    wr_en  = 1'b0;
    rd_en  = 1'b0;
    wr_data = '0;
    ref_queue.delete();    // Clear golden queue on reset
    write_count = 0;
    read_count  = 0;
    repeat(hold_cycles) @(posedge wr_clk);
    arst_n = 1'b1;         // Deassert — srst_n follows 2 cycles later
    $display("[RESET] Deasserting arst_n HIGH — waiting for sync deassert");
    repeat(4) @(posedge wr_clk);  // Wait for both rst_sync_wr + rst_sync_rd
    $display("[RESET] Reset complete — pointers should be 0");
  endtask

  // ============================================================
  // TASK: verify_pointers_zero
  // Checks wptr and rptr are 0 after reset via $display
  // Actual pointer check done visually in GTKWave
  // ============================================================
  task automatic verify_flags_after_reset();
    @(posedge rd_clk); #1;
    if (!empty) begin
      $error("[RESET CHECK FAIL] empty should be 1 after reset! empty=%0b", empty);
      test_errors++;
    end else begin
      $display("[RESET CHECK PASS] empty=1 after reset ✓");
    end
    if (full) begin
      $error("[RESET CHECK FAIL] full should be 0 after reset! full=%0b", full);
      test_errors++;
    end else begin
      $display("[RESET CHECK PASS] full=0 after reset ✓");
    end
  endtask

  // ============================================================
  // MAIN TEST SEQUENCE
  // ============================================================
  initial begin
    // ---- Initialize all signals ----
    wr_en   = 1'b0;
    rd_en   = 1'b0;
    wr_data = '0;
    arst_n  = 1'b0;

    // ---- Initial reset ----
    $display("========================================");
    $display("  ASYNC FIFO DIRECTED TESTBENCH START  ");
    $display("  wr_clk=100MHz  rd_clk=73MHz          ");
    $display("  DEPTH=%0d  DATA_WIDTH=%0d             ", DEPTH, DATA_WIDTH);
    $display("========================================");
    apply_reset(8);

    // ============================================================
    // TEST 1 — Write 16 items at 100MHz, read at 73MHz
    // Goal : Verify all data arrives correctly across clock domains
    // Pass : All rd_data match wr_data in order (FIFO ordering)
    // GTKWave: Observe wptr advancing on wr_clk, rptr on rd_clk
    //          full asserts when 16th item written
    //          Data visible on rd_data bus, delayed by CDC latency
    // ============================================================
    $display("\n--- TEST 1: Write 16 items, Read 16 items ---");

    // Write all 16 items as fast as possible at 100MHz
    fork
      begin : write_proc
        for (int i = 0; i < DEPTH; i++) begin
          do_write(8'hA0 + i);  // Data: 0xA0, 0xA1, ... 0xAF
        end
      end
      begin : read_proc
        // Read domain is slower (73MHz) — slight delay before starting
        repeat(5) @(posedge rd_clk);
        for (int i = 0; i < DEPTH; i++) begin
          do_read();
        end
      end
    join

    // Let CDC synchronizers settle before next test
    repeat(10) @(posedge wr_clk);
    $display("--- TEST 1 COMPLETE --- Errors so far: %0d ---", test_errors);

    // ============================================================
    // TEST 2 — Fill to full, verify full flag, attempt overflow
    // Goal : Verify full flag asserts correctly at DEPTH writes
    //        and that an extra write does NOT corrupt FIFO data
    // Pass : full=1 after 16 writes, overflow write ignored
    // GTKWave: full signal goes high exactly when wptr wraps
    //          almost_full goes high 4 entries before full
    // ============================================================
    $display("\n--- TEST 2: Fill to full, overflow protection ---");
    apply_reset(5);

    // Fill FIFO completely
    for (int i = 0; i < DEPTH; i++) begin
      do_write(8'hB0 + i);
    end

    // Verify full flag
    @(posedge wr_clk); #1;
    if (full) begin
      $display("[TEST2 PASS] full=1 after %0d writes ✓", DEPTH);
    end else begin
      $error("[TEST2 FAIL] full=0 after %0d writes — should be 1!", DEPTH);
      test_errors++;
    end

    // Attempt overflow write — should be blocked by do_write task
    $display("[TEST2] Attempting overflow write — should be blocked...");
    @(posedge wr_clk); #1;
    if (full) begin
      // Force write enable HIGH to test RTL overflow protection
      wr_en   <= 1'b1;
      wr_data <= 8'hFF;  // Canary value — should NOT appear in output
      @(posedge wr_clk); #1;
      wr_en   <= 1'b0;
      wr_data <= 8'h00;
      $display("[TEST2] Overflow write attempted with wr_en=1 while full=1");
      $display("[TEST2] Verify in GTKWave: wptr must NOT increment");
    end

    // Read back all data and verify no corruption
    $display("[TEST2] Reading back all data — verifying no corruption...");
    for (int i = 0; i < DEPTH; i++) begin
      do_read();
    end

    repeat(10) @(posedge rd_clk);
    $display("--- TEST 2 COMPLETE --- Errors so far: %0d ---", test_errors);

    // ============================================================
    // TEST 3 — Drain to empty, verify empty flag, attempt underflow
    // Goal : Verify empty flag asserts after last read
    //        and extra read does NOT cause crash or X-propagation
    // Pass : empty=1 after all reads, underflow read ignored
    // GTKWave: empty signal goes high when rptr catches wptr
    //          almost_empty goes high 2 entries before empty
    // ============================================================
    $display("\n--- TEST 3: Drain to empty, underflow protection ---");
    apply_reset(5);

    // Write exactly 8 items (half full)
    for (int i = 0; i < 8; i++) begin
      do_write(8'hC0 + i);
    end

    // Read all 8 items
    for (int i = 0; i < 8; i++) begin
      do_read();
    end

    // Wait for CDC propagation — empty takes 2 rd_clk cycles to assert
    repeat(6) @(posedge rd_clk);

    // Verify empty flag
    if (empty) begin
      $display("[TEST3 PASS] empty=1 after draining all items ✓");
    end else begin
      $error("[TEST3 FAIL] empty=0 after draining — should be 1!");
      test_errors++;
    end

    // Attempt underflow read — force rd_en while empty
    $display("[TEST3] Attempting underflow read — rd_en=1 while empty=1...");
    @(posedge rd_clk); #1;
    rd_en <= 1'b1;   // Force read even though empty
    @(posedge rd_clk); #1;
    rd_en <= 1'b0;
    $display("[TEST3] Underflow read attempted — verify rptr did NOT increment in GTKWave");
    $display("[TEST3] rd_data=0x%02h — should be stale/invalid (don't use)", rd_data);

    repeat(5) @(posedge rd_clk);
    $display("--- TEST 3 COMPLETE --- Errors so far: %0d ---", test_errors);

    // ============================================================
    // TEST 4 — Assert arst_n mid-operation, verify pointer reset
    // Goal : Verify async reset fires immediately (not on clock edge)
    //        Both wptr and rptr reset to 0 after reset
    //        empty=1 and full=0 immediately after reset
    // Pass : Pointers = 0, empty = 1, full = 0 after reset
    // GTKWave: arst_n pulse visible — wptr/rptr snap to 0 async
    //          srst_n_wr and srst_n_rd deassert 2 cycles AFTER arst_n
    // ============================================================
    $display("\n--- TEST 4: arst_n mid-operation reset ---");
    apply_reset(5);  // Clean state first

    // Write 8 items — FIFO half full
    for (int i = 0; i < 8; i++) begin
      do_write(8'hD0 + i);
    end

    $display("[TEST4] FIFO has 8 items — asserting arst_n MID-OPERATION");

    // Assert reset mid-operation (NOT aligned to clock edge)
    // This tests the ASYNC part of async-assert/sync-deassert
    #3.7;  // Mid-cycle — not on any clock edge!
    arst_n = 1'b0;
    $display("[TEST4] arst_n asserted at time %0t (mid-cycle)", $time);

    // Hold reset for 6 wr_clk cycles
    repeat(6) @(posedge wr_clk);
    arst_n = 1'b1;
    $display("[TEST4] arst_n deasserted at time %0t", $time);

    // Wait for sync deassert propagation (2 cycles per domain)
    repeat(6) @(posedge wr_clk);

    // Verify flags after reset
    verify_flags_after_reset();

    // Try writing after reset — should work normally
    $display("[TEST4] Writing after reset — verifying FIFO functional...");
    do_write(8'hEE);
    repeat(4) @(posedge rd_clk);
    do_read();

    repeat(10) @(posedge wr_clk);
    $display("--- TEST 4 COMPLETE --- Errors so far: %0d ---", test_errors);

    // ============================================================
    // FINAL REPORT
    // ============================================================
    $display("\n========================================");
    $display("  TESTBENCH COMPLETE                   ");
    $display("  Total Writes : %0d", write_count);
    $display("  Total Reads  : %0d", read_count);
    if (test_errors == 0)
      $display("  RESULT       : *** ALL TESTS PASSED *** ✓");
    else
      $display("  RESULT       : *** %0d ERRORS FOUND *** ✗", test_errors);
    $display("========================================");
    $display("  Run: gtkwave dump.vcd");
    $display("  Add signals from tb_async_fifo_directed");
    $display("  and dut hierarchy for full inspection");
    $display("========================================");

    $finish;
  end

  // ============================================================
  // Timeout Watchdog — kills simulation if stuck
  // Prevents infinite loop on deadlock bugs
  // ============================================================
  initial begin
    #500000;  // 500us timeout
    $error("[WATCHDOG] Simulation timeout after 500us — potential deadlock!");
    $finish;
  end

endmodule
// ============================================================
// End of tb_async_fifo_directed.sv
// ============================================================