# ML-DSA SampleInBall

Overview of component implementation completed this week:

- **`SampleInBall.hs` (Root Directory)**
  - Pure Haskell reference implementation for NIST FIPS 204 algorithms (Algorithm 15 `CoeffFromHalfByte` & Algorithm 29 `SampleInBall`).

- **`clash-hash/src/Reference/SampleInBall.hs` (Project Subdirectory)**
  - Integrated reference model combining algorithm logic with SHAKE256 XOF stream generation and modulo arithmetic.
