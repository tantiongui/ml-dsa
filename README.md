# NIST FIPS 204 ML-DSA Hardware Implementation

Pure Haskell reference models and Clash HDL hardware implementations for NIST FIPS 204 (ML-DSA) algorithms.

## Key Clash HDL Modules

- **CoeffFromHalfByte (Algorithm 15)**
  - Source: [my-clash-project/src/CoeffFromHalfByte.hs](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/src/CoeffFromHalfByte.hs)
  - Synthesized Verilog: [my-clash-project/verilog/CoeffFromHalfByte.topEntity/topEntity.v](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/verilog/CoeffFromHalfByte.topEntity/topEntity.v)
  - Summary: Converts 4-bit nibbles to polynomial coefficients in range [-\eta, \eta] with rejection sampling for ML-DSA-44, ML-DSA-65, and ML-DSA-87.

- **SampleInBall (Algorithm 29)**
  - Source: [my-clash-project/src/SampleInBall.hs](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/src/SampleInBall.hs)
  - Synthesized Verilog: [my-clash-project/verilog/SampleInBall.topEntity/topEntity.v](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/verilog/SampleInBall.topEntity/topEntity.v)
  - Summary: Generates 256-degree polynomials with Hamming weight \tau = 39 (\pm 1 non-zero coefficients) using a cycle-accurate Mealy state machine supporting single-cycle Fisher-Yates coefficient swaps and non-blocking rejection sampling. Fully verified against the golden reference model.

## Build and Verification

Build project:
```powershell
chcp 65001; $OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; stack build
```

Run test suite:
```powershell
stack test
```

Synthesize Verilog:
```powershell
stack exec clash -- --verilog src/SampleInBall.hs
```
