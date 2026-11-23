# CPAEP Project Template
- This project template is for the CPAEP class for the AY 2025-2026 in KU Leuven
- This template serves as a base repository for running RTL simulations.
- Preferrably, setup your work in a linux subsystem with Questasim tool.
- Please use the ESAT computers for this exercise.

# Quick Start
You can run the testbenches with Questasim or with Verilator. Both run the same testbench and should give the same result.

## Questasim
We already prepared the entire Questasim simulation setup for you. Simply invoke the command below to run a simulation without GUI.

```bash
make TEST_MODULE=tb_one_mac_gemm questasim-run
```

To run with a GUI do:

```bash
make TEST_MODULE=tb_one_mac_gemm questasim-run-gui
```

In either case, you should see a log that ends with:

```bash
Some long log of the previous tests.
...
# ==================================================================
#  RESULTS
# ------------------------------------------------------------------
#  Case     |    M    K    N |   Cycles |       Energy | Check
# ------------------------------------------------------------------
#  GeMM 1   |    4   64   16 |     4096 |       151524 | PASS
#  GeMM 2   |   16   64    4 |     4096 |       151532 | PASS
#  GeMM 3   |   32   32   32 |    32768 |      1244801 | PASS
#  GeMV 1   |   32   32    1 |     1024 |        38908 | PASS
#  GeMV 2   |   64   32    1 |     2048 |        77819 | PASS
#  GeMV 3   |   64   64    1 |     4096 |       151477 | PASS
# ------------------------------------------------------------------
#  Area: 4 area units
# ==================================================================
#
# All 6 cases passed!
# ** Note: $finish    : tb/tb_one_mac_gemm.sv(345)
#    Time: 482166 ns  Iteration: 0  Instance: /tb_one_mac_gemm
# End time: 14:07:31 on Nov 23,2026, Elapsed time: 0:00:02
# Errors: 0, Warnings: 1
```

## Verilator
Verilator runs in this project. You need to download it at this [link](https://verilator.org/guide/latest/install.html).

Inside the repo run:

```bash
make TEST_MODULE=tb_one_mac_gemm all
./bin/tb_one_mac_gemm
```

The build puts the simulation binary in `bin/`. The `make` target does not track changes to your source files, so delete the old binary before you rebuild:

```bash
rm -f bin/tb_one_mac_gemm
make TEST_MODULE=tb_one_mac_gemm all
```

You should see a log that ends with:

```bash
Some long log of the previous tests.
...
==================================================================
 RESULTS
------------------------------------------------------------------
 Case     |    M    K    N |   Cycles |       Energy | Check
------------------------------------------------------------------
 GeMM 1   |    4   64   16 |     4096 |       151532 | PASS
 GeMM 2   |   16   64    4 |     4096 |       151477 | PASS
 GeMM 3   |   32   32   32 |    32768 |      1244951 | PASS
 GeMV 1   |   32   32    1 |     1024 |        38909 | PASS
 GeMV 2   |   64   32    1 |     2048 |        77816 | PASS
 GeMV 3   |   64   64    1 |     4096 |       151546 | PASS
------------------------------------------------------------------
 Area: 4 area units
==================================================================

All 6 cases passed!
- tb/tb_one_mac_gemm.sv:345: Verilog $finish
- S i m u l a t i o n   R e p o r t: Verilator 5.024 2024-04-05
- Verilator: $finish at 482ns; walltime 0.053 s; speed 0.000 s/s
```