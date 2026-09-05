#include <cstdlib>

#include <verilated.h>

#include "VComponent_SampleInBall.h"

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  VComponent_SampleInBall *top = new VComponent_SampleInBall;

  while(!Verilated::gotFinish()) {
    top->eval();
  }

  top->final();

  delete top;

  return EXIT_SUCCESS;
}

