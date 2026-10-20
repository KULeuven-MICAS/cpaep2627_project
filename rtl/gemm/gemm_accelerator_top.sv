//---------------------------
// The 1-MAC GeMM accelerator top module
//
// Description:
// This module implements a simple General Matrix-Matrix Multiplication (GeMM)
// accelerator using a single Multiply-Accumulate (MAC) Processing Element (PE).
// It interfaces with three SRAMs for input matrices A and B, and output matrix C.
//
// It includes a controller to manage the GeMM operation and address generation logic
// for accessing the SRAMs based on the current matrix sizes and counters.
//
// Parameters:
// - InDataWidth  : Width of the input data (matrix elements).
// - OutDataWidth : Width of the output data (result matrix elements).
// - AddrWidth    : Width of the address bus for SRAMs.
// - SizeAddrWidth: Width of the size parameters for matrices.
//
// Ports:
// - clk_i        : Clock input.
// - rst_ni       : Active-low reset input.
// - start_i      : Start signal to initiate the GeMM operation.
// - M_size_i     : Size of matrix M (number of rows in A and C
// - K_size_i     : Size of matrix K (number of columns in A and rows in B).
// - N_size_i     : Size of matrix N (number of columns in B and C).
// - sram_a_addr_o: Address output for SRAM A.
// - sram_b_addr_o: Address output for SRAM B.
// - sram_c_addr_o: Address output for SRAM C.
// - sram_a_rdata_i: Data input from SRAM A.
// - sram_b_rdata_i: Data input from SRAM B.
// - sram_c_wdata_o: Data output to SRAM C.
// - sram_c_we_o  : Write enable output for SRAM C.
// - done_o       : Done signal indicating completion of the GeMM operation.
//---------------------------

module gemm_accelerator_top #(
  parameter int unsigned InDataWidth = 8,
  parameter int unsigned OutDataWidth = 32,
  parameter int unsigned AddrWidth = 16,
  parameter int unsigned SizeAddrWidth = 8
) (
  input  logic                            clk_i,
  input  logic                            rst_ni,
  input  logic                            start_i,
  input  logic        [SizeAddrWidth-1:0] M_size_i,
  input  logic        [SizeAddrWidth-1:0] K_size_i,
  input  logic        [SizeAddrWidth-1:0] N_size_i,
  output logic        [    AddrWidth-1:0] sram_a_addr_o,
  output logic        [    AddrWidth-1:0] sram_b_addr_o,
  output logic        [    AddrWidth-1:0] sram_c_addr_o,
  input  logic signed [  InDataWidth-1:0] sram_a_rdata_i,
  input  logic signed [  InDataWidth-1:0] sram_b_rdata_i,
  output logic signed [ OutDataWidth-1:0] sram_c_wdata_o,
  output logic                            sram_c_we_o,
  output logic                            done_o
);

  //---------------------------
  // Wires
  //---------------------------
  logic [SizeAddrWidth-1:0] M_count;
  logic [SizeAddrWidth-1:0] K_count;
  logic [SizeAddrWidth-1:0] N_count;

  logic busy;
  logic valid_data;  // A/B read data at the MAC inputs is valid
  logic init_save;   // MAC loads the product instead of accumulating

  // C address pipeline (see address generation below)
  logic [AddrWidth-1:0] sram_c_addr_q;

  //---------------------------
  // DESIGN NOTE:
  // This is a simple GeMM accelerator design using a single MAC PE.
  // The controller manages just the counting capabilities.
  // Check the gemm_controller.sv file for more details.
  //
  // Essentially, it tightly couples the counters and an FSM together.
  // The address generation logic is just after this controller.
  //
  // You have the option to combine the address generation and controller
  // all in one module if you prefer. We did this intentionally to separate tasks.
  //---------------------------

  // Main GeMM controller
  gemm_controller #(
    .AddrWidth      ( SizeAddrWidth )
  ) i_gemm_controller (
    .clk_i          ( clk_i       ),
    .rst_ni         ( rst_ni      ),
    .start_i        ( start_i     ),
    .input_valid_i  ( 1'b1        ),  // Always valid in this simple design
    .result_valid_o ( sram_c_we_o ),
    .data_valid_o   ( valid_data  ),
    .init_save_o    ( init_save   ),
    .busy_o         ( busy        ),
    .done_o         ( done_o      ),
    .M_size_i       ( M_size_i    ),
    .K_size_i       ( K_size_i    ),
    .N_size_i       ( N_size_i    ),
    .M_count_o      ( M_count     ),
    .K_count_o      ( K_count     ),
    .N_count_o      ( N_count     )
  );

  //---------------------------
  // DESIGN NOTE:
  // This part is the address generation logic for the input and output SRAMs.
  // In our example, we made the assumption that both matrices A and B
  // are stored in row-major order.
  //
  // Please adjust this part to align with your designed memory layout
  // The counters are used for the matrix A and matrix B address generation.
  //
  // The SRAMs have a synchronous read: the A and B addresses issued in
  // cycle t give data at the MAC in cycle t+1, and the finished C element
  // is in the MAC output in cycle t+2. So the C address is the counter
  // value delayed by two cycles, lined up with sram_c_we_o.
  //
  // Just be careful to know on which cycle the addresses are valid.
  // Align it carefully with the testbench's memory control.
  //---------------------------

  // Input addresses for matrices A and B
  assign sram_a_addr_o = (M_count * K_size_i + K_count);
  assign sram_b_addr_o = (K_count * N_size_i + N_count);

  // Output address for matrix C (two cycle delay)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sram_c_addr_q <= '0;
      sram_c_addr_o <= '0;
    end else begin
      sram_c_addr_q <= (M_count * N_size_i + N_count);
      sram_c_addr_o <= sram_c_addr_q;
    end
  end

  //---------------------------
  // DESIGN NOTE:
  // This part is the MAC PE instantiation and data path logic.
  // Check the general_mac_pe.sv file for more details.
  //
  // In this example, we only use a single MAC PE hence it is a simple design.
  // However, you can expand this part to support multiple PEs
  // by adjusting the data widths and input/output connections accordingly.
  //
  // Systemverilog has a useful mechanism to generate multiple instances
  // using generate-for loops.
  // Below is an example of a 2D generate-for loop to create a grid of PEs.
  //
  // ----------- BEGIN CODE EXAMPLE -----------
  // genvar m, k, n;
  //
  //   for (m = 0; m < M; m++) begin : gem_mac_pe_m
  //     for (n = 0; n < N; n++) begin : gem_mac_pe_n
  //         mac_module #(
  //           < insert parameters >
  //         ) i_mac_pe (
  //           < insert port connections >
  //         );
  //     end
  //   end
  // ----------- END CODE EXAMPLE -----------
  // 
  // There are many guides on the internet (or even ChatGPT) about generate-for loops.
  // We will give it as an exercise to you to modify this part to support multiple MAC PEs.
  // 
  // When dealing with multiple PEs, be careful with the connection alignment
  // across different PEs as it can be tricky to debug later on.
  // Plan this very carefully, especially when delaing with the correcet data ports
  // data widths, slicing, valid signals, and so much more.
  //
  // Additionally, this MAC PE is already output stationary.
  // You have the freedom to change the dataflow as you see fit.
  //---------------------------

  // The MAC PE instantiation and data path logics
  general_mac_pe #(
    .InDataWidth  ( InDataWidth            ),
    .NumInputs    ( 1                      ),
    .OutDataWidth ( OutDataWidth           )
  ) i_mac_pe (
    .clk_i        ( clk_i                  ),
    .rst_ni       ( rst_ni                 ),
    .a_i          ( sram_a_rdata_i         ),
    .b_i          ( sram_b_rdata_i         ),
    .a_valid_i    ( valid_data             ),
    .b_valid_i    ( valid_data             ),
    .init_save_i  ( init_save              ),
    .acc_clr_i    ( !busy                  ),
    .c_o          ( sram_c_wdata_o         )
  );

endmodule
