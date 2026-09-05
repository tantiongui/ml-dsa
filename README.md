# NIST FIPS 204 ML-DSA Hardware Implementation

Pure Haskell reference models and Clash HDL hardware implementations for NIST FIPS 204 (ML-DSA) algorithms.

## Key Modules

- **SampleInBall (Algorithm 29)**
  - Source: `clash-hash/src/Component/SampleInBall.hs`
  - Summary: Generates 256-degree polynomials with Hamming weight $\tau = 39$ ($\pm 1$ non-zero coefficients) using a Mealy state machine. Conforms to NIST FIPS 204 Appendix C loop bounds with cutoff timeout and intermediate state zeroization.
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
Runs the full pipeline (HDL gen, Yosys synthesis, OpenSTA timing):
```bash
python3 scripts/bench.py SampleInBall
```

### 4. Loop Bound & Probability Analysis
```bash
# Theoretical recurrence analysis (FIPS 204 Appendix C)
python3 scripts/sample_in_ball_bounds.py

# Monte Carlo empirical simulation (1,000,000 trials)
python3 scripts/sim_sample_in_ball.py
```

## Benchmark Results

Target period: 5.0 ns (200 MHz) with Nangate 45nm standard cell library.

| Module | Cells | Area ($\mu\text{m}^2$) | Critical Path (ns) | Worst Slack (ns) | WNS / TNS (ns) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| `SampleInBall` | 11,607 | 14,694.372 | 1.24 | 3.72 | 0.000 / 0.000 |
