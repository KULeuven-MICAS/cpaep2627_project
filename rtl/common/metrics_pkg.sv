//-----------------------------
// Metrics package (simulation only)
//
// Description: Shared counters for area and energy logging.
// Any module can add to these with metrics_pkg::area += ...,
// no matter which testbench is the top. This replaces hierarchical
// references like tb_one_mac_gemm.area, which only resolve when
// that one testbench is the top module.
//
// Compile this file before any module that uses it
// (it is the first line of the flists that need it).
//-----------------------------
package metrics_pkg;
  // Area: summed once at time 0 by each module's initial block
  real area = 0;
  // Energy: accumulated during simulation
  real energy = 0;
endpackage
