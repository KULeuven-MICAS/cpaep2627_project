// Task to start the accelerator
// and wait for it to finish its task.
// Returns the number of cycles it took in cycle_count.
task automatic start_and_wait_gemm(
  output int unsigned cycle_count
);
begin
  cycle_count = 0;
  // Start the GEMM operation
  // Drive and sample 1 time unit after the clock edge (clk_delay)
  // so the testbench never races with the DUT flip-flops.
  clk_delay(1);
  start = 1'b1;
  clk_delay(1);
  start = 1'b0;
  while (done == 1'b0) begin
  clk_delay(1);
  cycle_count = cycle_count + 1;
  if (cycle_count > 100000) begin
    $display("ERROR: GEMM operation timeout after %0d cycles", cycle_count);
    $fatal;
  end
  end
  // done_o is high in the same cycle as the last SRAM C write.
  // Pass one more clock edge so that write has landed before verifying.
  clk_delay(1);
end
endtask

// Task to verify the resulting matrix.
// Returns the number of mismatches in num_errors.
task automatic verify_result_c(
  input  logic signed [OutDataWidth-1:0] golden_data [DataDepth],
  input  logic signed [OutDataWidth-1:0] actual_data [DataDepth],
  input  logic        [   AddrWidth-1:0] num_data,
  input  logic                           fatal_on_mismatch,
  output int unsigned                    num_errors
);
begin
  num_errors = 0;
  // Compare with SRAM C contents
  for (int unsigned addr = 0; addr < num_data; addr++) begin
    if (golden_data[addr] !== actual_data[addr]) begin
      num_errors++;
      $display("ERROR: Mismatch at address %0d: expected %h, got %h",
               addr, golden_data[addr], actual_data[addr]);
      if (fatal_on_mismatch)
        $fatal;
    end
  end
end
endtask
