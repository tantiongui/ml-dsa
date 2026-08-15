# NIST FIPS 204 ML-DSA (Post-Quantum Cryptography) Hardware/Software Co-Design

This repository contains pure Haskell Golden Reference Models, Clash HDL hardware modules, and synthesized Verilog source code for NIST FIPS 204 (ML-DSA) algorithms.

## 🚀 Newly Implemented Clash HDL Modules (`my-clash-project`)

### 1. `CoeffFromHalfByte` (NIST FIPS 204 Algorithm 15)
- **Source**: [`my-clash-project/src/CoeffFromHalfByte.hs`](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/src/CoeffFromHalfByte.hs)
- **Verilog**: [`my-clash-project/verilog/CoeffFromHalfByte.topEntity/topEntity.v`](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/verilog/CoeffFromHalfByte.topEntity/topEntity.v)
- **Description**: Converts 4-bit nibbles $b \in [0..15]$ to polynomial coefficients in $[-\eta, \eta]$. Supports $\eta = 2$ (ML-DSA-44 / ML-DSA-87) and $\eta = 4$ (ML-DSA-65). Maps `Nothing` outputs to hardware rejection flags.

### 2. `SampleInBall` (NIST FIPS 204 Algorithm 29)
- **Source**: [`my-clash-project/src/SampleInBall.hs`](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/src/SampleInBall.hs)
- **Verilog**: [`my-clash-project/verilog/SampleInBall.topEntity/topEntity.v`](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/verilog/SampleInBall.topEntity/topEntity.v)
- **Description**: Generates a 256-degree polynomial $c \in R_q$ with Hamming weight $\tau = 39$ ($\pm 1$ non-zero coefficients) using a cycle-accurate Mealy state machine (`sampleInBallT`). Performs single-clock-cycle Fisher-Yates coefficient swaps ($c[i] \leftarrow c[j]$, $c[j] \leftarrow \text{signVal}$) and handles rejection sampling ($j > i$) without clock stalling.
- **Verification**: Fully verified against the pure Haskell Golden Reference Model (`verifySampleInBall => True`, non-zero count = 39). Integrated with Tasty and Hedgehog property test suites (`stack test`).

---

## 📁 Repository Structure

- **`SampleInBall.hs`** (Root Directory)
  - Pure Haskell reference implementation for NIST FIPS 204 algorithms (Algorithm 15 `CoeffFromHalfByte` & Algorithm 29 `SampleInBall`).

- **`my-clash-project/`** (Clash HDL & Hardware Project)
  - **`src/CoeffFromHalfByte.hs`**: Algorithm 15 Clash module.
  - **`src/SampleInBall.hs`**: Algorithm 29 Clash hardware FSM.
  - **`tests/Tests/SampleInBallTest.hs`**: Automated unit & property tests.
  - **`verilog/`**: Synthesizable Verilog-2001 output files (`topEntity.v`).

- **`clash-hash/`** (Project Core Subdirectory)
  - Integrated reference model combining algorithm logic with SHAKE256 XOF stream generation and modulo arithmetic.

---

## 🛠️ Build & Verification Instructions

### 1. Build Clash Project
```powershell
chcp 65001; $OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; stack build
```

### 2. Run Test Suite
```powershell
stack test
```

### 3. Synthesize Verilog Code
```powershell
stack exec clash -- --verilog src/SampleInBall.hs
```
