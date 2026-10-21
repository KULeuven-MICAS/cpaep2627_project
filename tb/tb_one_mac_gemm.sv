module tb_one_mac_gemm;
  //---------------------------
  // Design Time Parameters
  //---------------------------

  //---------------------------
  // DESIGN NOTE:
  // Parameters are a way to customize your design at
  // compile time. Here we define the data width,
  // memory depth, and number of ports for the
  // multi-port memory instances used in the DUT.
  //
  // In other test benches, you can also have test parameters,
  // such as the number of tests to run, or the sizes of
  // matrices to be used in the tests.
  //
  // You can customize these parameters as needed.
  // Or you can also add your own parameters.
  //---------------------------

  // General Parameters
  parameter int unsigned InDataWidth   = 8;
  parameter int unsigned OutDataWidth  = 32;
  parameter int unsigned DataDepth     = 4096;
  parameter int unsigned AddrWidth     = (DataDepth <= 1) ? 1 : $clog2(DataDepth);
  parameter int unsigned SizeAddrWidth = 8;

  //---------------------------
  // Test cases
  //---------------------------
  // GeMM: C (M x N) = A (M x K) * B (K x N)
  // GeMV: y (M x 1) = A (M x K) * x (K x 1), which is a GeMM with N = 1
  //
  // To add a case, add a line below and bump NumCases.
  //---------------------------
  typedef struct {
    string       name;
    int unsigned M;
    int unsigned K;
    int unsigned N;
  } test_case_t;

  localparam int unsigned NumCases = 6;

  test_case_t test_cases [NumCases] = '{
    //  name       M   K   N
    '{"GeMM 1",   4, 64, 16},
    '{"GeMM 2",  16, 64,  4},
    '{"GeMM 3",  32, 32, 32},
    '{"GeMV 1",  32, 32,  1},
    '{"GeMV 2",  64, 32,  1},
    '{"GeMV 3",  64, 64,  1}
  };

  // Per-case results, printed in the summary at the end
  int unsigned case_cycles [NumCases];
  real         case_energy [NumCases];
  int unsigned case_errors [NumCases];

  //---------------------------
  // Wires
  //---------------------------

  // Size control
  logic [SizeAddrWidth-1:0] M_i, K_i, N_i;

  // Clock, reset, and other signals
  logic clk_i;
  logic rst_ni;
  logic start;
  logic done;
  logic [AddrWidth-1:0] test_depth;

  //---------------------------
  // Memory
  //---------------------------
  // Golden data dump
  logic signed [OutDataWidth-1:0] G_memory [DataDepth];

  // Memory control
  logic [AddrWidth-1:0] sram_a_addr;
  logic [AddrWidth-1:0] sram_b_addr;
  logic [AddrWidth-1:0] sram_c_addr;
  logic                 sram_a_re;
  logic                 sram_b_re;

  // Memory access
  logic signed [ InDataWidth-1:0] sram_a_rdata;
  logic signed [ InDataWidth-1:0] sram_b_rdata;
  logic signed [OutDataWidth-1:0] sram_c_wdata;
  logic                           sram_c_we;

  //---------------------------
  // Declaration of input and output memories
  //---------------------------

  //---------------------------
  // DESIGN NOTE:
  // These are where the memories are instantiated for the DUT.
  // You can modify the data width and data depth parameters.
  //
  // This can be useful for increasing your memory bandwidth.
  // However, you need to think about and take care of how to,
  // initialize the memories accordingly.
  // That includes knowing how to pack the data accordingly.
  //
  // Make sure that the connection for the address, data, and wen
  // signals are consistent with the number of ports.
  //
  // Refer to the single_port_memory.sv and 
  // tb_single_port_memory.sv file for more details.
  //---------------------------

  // Input memory A
  // Note: this is read only
  single_port_memory #(
    .DataWidth     ( InDataWidth  ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_a (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_a_addr  ),
    .mem_re_i      ( sram_a_re    ),
    .mem_we_i      ( '0           ),
    .mem_wr_data_i ( '0           ),
    .mem_rd_data_o ( sram_a_rdata )
  );

  // Input memory B
  // Note: this is read only
  single_port_memory #(
    .DataWidth     ( InDataWidth  ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_b (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_b_addr  ),
    .mem_re_i      ( sram_b_re    ),
    .mem_we_i      ( '0           ),
    .mem_wr_data_i ( '0           ),
    .mem_rd_data_o ( sram_b_rdata )
  );

  // Output memory C
  // Note: this is write only
  single_port_memory #(
    .DataWidth     ( OutDataWidth ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_c (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_c_addr  ),
    .mem_re_i      ( '0           ),
    .mem_we_i      ( sram_c_we    ),
    .mem_wr_data_i ( sram_c_wdata ),
    .mem_rd_data_o ( /* unused */ )
  );

  //---------------------------
  // DUT instantiation
  //---------------------------
  gemm_accelerator_top #(
    .InDataWidth   ( InDataWidth   ),
    .OutDataWidth  ( OutDataWidth  ),
    .AddrWidth     ( AddrWidth     ),
    .SizeAddrWidth ( SizeAddrWidth )
  ) i_dut (
    .clk_i          ( clk_i        ),
    .rst_ni         ( rst_ni       ),
    .start_i        ( start        ),
    .N_size_i       ( N_i          ),
    .M_size_i       ( M_i          ),
    .K_size_i       ( K_i          ),
    .sram_a_addr_o  ( sram_a_addr  ),
    .sram_b_addr_o  ( sram_b_addr  ),
    .sram_c_addr_o  ( sram_c_addr  ),
    .sram_a_re_o    ( sram_a_re    ),
    .sram_b_re_o    ( sram_b_re    ),
    .sram_a_rdata_i ( sram_a_rdata ),
    .sram_b_rdata_i ( sram_b_rdata ),
    .sram_c_wdata_o ( sram_c_wdata ),
    .sram_c_we_o    ( sram_c_we    ),
    .done_o         ( done         )
  );

  //---------------------------
  // Tasks and functions
  //---------------------------
  `include "includes/common_tasks.svh"
  `include "includes/test_tasks.svh"
  `include "includes/test_func.svh"

  // Metrics variables live in metrics_pkg (rtl/common/metrics_pkg.sv):
  // - metrics_pkg::area   starts at 0, each module adds its area at time 0
  // - metrics_pkg::energy is reset right before each case starts and read
  //                       right after it is done, so it holds one case only

  //---------------------------
  // Test control
  //---------------------------

  // Clock generation
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;  // 100MHz clock
  end

  //---------------------------
  // DESIGN NOTE:
  //
  // The sequence driver is usually the main stimulus
  // generator for the test bench. Here is where
  // you define the sequence of operations to be
  // performed during the simulation.
  //
  // It often starts with an initial reset sequence,
  // by loading default values and asserting the reset.
  //
  // We also do for-loops to run multiple tests
  // with different input parameters. In this case,
  // we loop over the fixed GeMM and GeMV sizes
  // listed in test_cases at the top of this file.
  //
  // You can also customize in here the way
  // the memories are initialized, how the golden
  // results are generated, and how the results
  // are verified.
  //
  // Refer to the tasks and functions included above
  // for more details.
  //---------------------------

  // Sequence driver
  initial begin

    // Initial reset
    start  = 1'b0;
    M_i    = '0;
    K_i    = '0;
    N_i    = '0;
    rst_ni = 1'b0;
    #50;
    rst_ni = 1'b1;

    foreach (test_cases[c]) begin
      M_i = test_cases[c].M;
      K_i = test_cases[c].K;
      N_i = test_cases[c].N;

      $display("[%0s] A (%0d x %0d) * B (%0d x %0d) -> C (%0d x %0d)",
               test_cases[c].name, M_i, K_i, K_i, N_i, M_i, N_i);

      //---------------------------
      // DESIGN NOTE:
      // You will most likely modify this part
      // to initialize the input memories
      // according to your design requirements.
      //
      // In here, we simply fill the memories
      // with random data for testing.
      //
      // We assume a row-major storage for both matrices A and B.
      // Row major means that the elements of each row
      // are stored in contiguous memory locations.
      //
      // We also make the assumption that the matrix output C
      // will be stored in row-major format as well.
      //
      // Take note that you WILL change this part according to your design.
      // Just make sure that the way you initialize the memories
      // is consistent with the way you generate the golden results
      // and the way your DUT reads/writes the data.
      //
      // The tricky part here is that since the data accesses are
      // shared within a single long bit-width (suppose you use longer)
      // memory word. For example, if your memory word is 32 bits wide
      // and your data width is 8 bits, then you can pack
      // 4 data elements in a single memory word.
      // So when you initialize the memory, you need to
      // make sure that the data elements are packed
      // correctly within each memory word.
      //---------------------------

      // Initialize memories with random data
      for (integer m = 0; m < M_i; m++) begin
        for (integer k = 0; k < K_i; k++) begin
          i_sram_a.memory[m*K_i+k] = $urandom() % (2 ** InDataWidth);
        end
      end

      for (integer k = 0; k < K_i; k++) begin
        for (integer n = 0; n < N_i; n++) begin
          i_sram_b.memory[k*N_i+n] = $urandom() % (2 ** InDataWidth);
        end
      end

      // Generate golden result
      gemm_golden(M_i, K_i, N_i, i_sram_a.memory, i_sram_b.memory, G_memory);

      // Just delay 1 cycle
      clk_delay(1);

      // Count energy for this case only: from start until done
      metrics_pkg::energy = 0;
      start_and_wait_gemm(case_cycles[c]);
      case_energy[c] = metrics_pkg::energy;

      // Verify the result
      test_depth = M_i * N_i;
      verify_result_c(G_memory, i_sram_c.memory, test_depth,
                      0, // Set this to 1 to make mismatches fatal
                      case_errors[c]);

      $display("[%0s] %0s: %0d cycles, %0.0f energy units\n",
               test_cases[c].name, (case_errors[c] == 0) ? "PASS" : "FAIL",
               case_cycles[c], case_energy[c]);

      // Just some trailing cycles
      // For easier monitoring in waveform
      clk_delay(10);
    end

    print_report();
    $finish;
  end

  //---------------------------
  // Final report
  //---------------------------
  // Left-align a string to a fixed width
  // (avoids %-Ns, which some simulators format differently)
  function automatic string pad(string str, int unsigned width);
    while (str.len() < width) str = {str, " "};
    return str;
  endfunction

  task automatic print_report();
    int unsigned num_failed = 0;

    $display("");
    $display("==================================================================");
    $display(" RESULTS");
    $display("------------------------------------------------------------------");
    $display(" %s | %4s %4s %4s | %8s | %12s | %s",
             pad("Case", 8), "M", "K", "N", "Cycles", "Energy", "Check");
    $display("------------------------------------------------------------------");
    foreach (test_cases[c]) begin
      $display(" %s | %4d %4d %4d | %8d | %12.0f | %s",
               pad(test_cases[c].name, 8), test_cases[c].M, test_cases[c].K,
               test_cases[c].N, case_cycles[c], case_energy[c],
               (case_errors[c] == 0) ? "PASS" : "FAIL");
      if (case_errors[c] != 0) num_failed++;
    end
    $display("------------------------------------------------------------------");
    $display(" Area: %0.0f area units", metrics_pkg::area);
    $display("==================================================================");
    $display("");

    if (num_failed != 0) begin
      $fatal(1, "%0d of %0d cases FAILED", num_failed, NumCases);
    end
    $display("All %0d cases passed!", NumCases);
  endtask

endmodule
