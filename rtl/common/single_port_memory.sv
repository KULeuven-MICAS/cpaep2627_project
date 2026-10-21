//-----------------------------
// Single Port Memory Module
//
// Description: This module implements a single-port memory with
// configurable data width and depth. Both reads and writes are
// synchronous: the read data for the address presented in cycle t
// appears on mem_rd_data_o in cycle t+1 (one cycle read latency).
// A read only happens when mem_re_i is high; otherwise the read output
// keeps its previous value. Reads and writes have separate enables so
// each can be counted on its own (e.g. for energy logging).
// Being single-port, mem_re_i and mem_we_i must not be high together.
//
// Parameters:
// - DataWidth: Width of the data bus (default: 8 bits)
// - DataDepth: Depth of the memory (default: 4096 entries)
// - AddrWidth: Width of the address bus (calculated based on DataDepth)
//
// Ports:
// - clk_i: Clock input
// - rst_ni: Active low reset input
// - mem_addr_i: Memory address input
// - mem_re_i: Memory read enable input
// - mem_we_i: Memory write enable input
// - mem_wr_data_i: Memory write data input
// - mem_rd_data_o: Memory read data output
//-----------------------------

//-----------------------------
// DESIGN NOTE:
// You are allowed to modify the Datadepth and
// DataWidth parameters to suit your design requirements.
//-----------------------------
module single_port_memory #(
    parameter int unsigned DataWidth = 8,
    parameter int unsigned DataDepth = 4096,
    parameter int unsigned AddrWidth = (DataDepth <= 1) ? 1 : $clog2(DataDepth)
) (
    input  logic                        clk_i,
    input  logic                        rst_ni,
    input  logic        [AddrWidth-1:0] mem_addr_i,
    input  logic                        mem_re_i,
    input  logic                        mem_we_i,
    input  logic signed [DataWidth-1:0] mem_wr_data_i,
    output logic signed [DataWidth-1:0] mem_rd_data_o
);

  // Memory array
  logic signed [DataWidth-1:0] memory[DataDepth];

  // Memory read access (registered, one cycle latency)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mem_rd_data_o <= '0;
    end else if (mem_re_i) begin
      mem_rd_data_o <= memory[mem_addr_i];
    end
  end

  // Memory write access
  always_ff @(posedge clk_i) begin
    // Write when write enable is asserted
    if (mem_we_i) begin
      memory[mem_addr_i] <= mem_wr_data_i;
    end
  end

  // Single port: only one access per cycle
  always @(posedge clk_i) begin
    if (rst_ni && mem_re_i && mem_we_i) begin
      $error("%m: mem_re_i and mem_we_i are both high at address %0d", mem_addr_i);
    end
  end

  //--------------------------------
  // IMPORTANT! Energy logging
  // For memory, energy is dependent on the number of bits during a read or write
  // From the table we had:
  // 1 bit read or write = 2 energy units per bit
  // So for a 32-bit read or write, it would consume 32 * 2 = 64 energy units
  // In this case, every clock cycle where the read or write enable
  // is high is one access, and costs DataWidth * 2 units.
  // (Counting on a change of the enable would count a long burst
  // of back-to-back reads only once.)
  //--------------------------------

  always @ (posedge clk_i) begin
    if (mem_re_i || mem_we_i) begin
      metrics_pkg::energy += DataWidth * 2;
    end
  end

endmodule
