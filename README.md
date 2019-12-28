### What is this?

A RISC-V CPU project.

### Feature?

-  5 stage pipeline with data forwarding
-  static branch prediction (always predicts "not taken")
-   instruction cache (direct mapping)
-   data cache (direct mapping)，**doesn't work on qsort.v, so moved to backup.**
-   FPGA test passed

### Performance?

Take `pi.c` for example:

- 100 Hz: 2.171875 s
- 150 Hz: failed.
- 200 Hz: failed.

### What to do next?

- implement dynamic prediction

- implement JAL and JALR in IF stage

- better structure for IF stage

- cache optimization like victim cache

- eliminate inferring latch

- take higher order bit for cache index

  