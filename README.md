# NIST FIPS 204 ML-DSA Hardware Implementation

Pure Haskell reference models and Clash HDL hardware implementations for NIST FIPS 204 (ML-DSA) algorithms.

## Key Modules

- **SampleInBall (Algorithm 29)**
  - Source: `clash-hash/src/Component/SampleInBall.hs`
  - Summary: Generates 256-degree polynomials with Hamming weight $\tau = 39$ ($\pm 1$ non-zero coefficients) using a Mealy state machine supporting single-cycle Fisher-Yates coefficient swaps and non-blocking rejection sampling.
- **CoeffFromHalfByte (Algorithm 15)**
  - Source: `clash-hash/src/Component/CoeffFromHalfByte.hs`
  - Summary: Converts 4-bit nibbles to polynomial coefficients in range $[-\eta, \eta]$ with rejection sampling for ML-DSA-44, 65, and 87.

## Getting Started

All development and benchmarking scripts are located under `clash-hash/`:

```bash
cd clash-hash
export PATH="$HOME/.ghcup/bin:$PATH"
```

### 1. Run Tests
```bash
stack test
```

### 2. Verilog Synthesis
Generates Verilog/SystemVerilog from Clash and performs logic synthesis:
```bash
# Synthesize SampleInBall
python3 scripts/synth.py SampleInBall

# Synthesize CoeffFromHalfByte
python3 scripts/synth.py CoeffFromHalfByte
```

### 3. Run Benchmark
Runs the full pipeline:
```bash
python3 scripts/bench.py SampleInBall
```

## Benchmark Results

| Module | Cells | Area ($\mu\text{m}^2$) | Critical Path (ns) | Worst Slack (ns) | WNS / TNS (ns) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| `SampleInBall` (AXI4-Stream 64-bit Receiver) | 10,990 | 14,050.918 | 1.28 | 3.68 | 0.000 / 0.000 |
| `SampleInBall` (Standalone Compact Core) | 7,406 | 9,630.264 | 0.81 | 4.15 | 0.000 / 0.000 |
