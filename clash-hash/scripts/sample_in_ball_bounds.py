#!/usr/bin/env python3
"""
NIST FIPS 204 (ML-DSA) Appendix C: SampleInBall Loop Bound & Probability Analysis
Calculates exact rational probabilities P(n, tau) using arbitrary-precision arithmetic,
verifies Table 3 bounds, computes statistical moments, and outputs log2(P) cutoff thresholds.
"""

from fractions import Fraction
import math
import sys

def compute_recurrence(tau_max=60, n_max=250):
    """
    Computes P(n, tau): the probability that more than n bytes of output
    will be required from H during an execution of SampleInBall for parameter tau.

    Recurrence relation (FIPS 204, Appendix C):
      P(n, tau) = 1                                                         if n <= 8
      P(n, 1)   = 0                                                         if n > 8
      P(n, tau) = (257 - tau)/256 * P(n-1, tau-1) + (tau - 1)/256 * P(n-1, tau)  if tau > 1 and n > 8
    """
    dp_prev = {t: Fraction(1, 1) for t in range(1, tau_max + 1)}
    
    p_table = {8: dp_prev}
    
    for n in range(9, n_max + 1):
        dp_curr = {1: Fraction(0, 1)}
        for tau in range(2, tau_max + 1):
            term1 = Fraction(257 - tau, 256) * dp_prev[tau - 1]
            term2 = Fraction(tau - 1, 256) * dp_prev[tau]
            dp_curr[tau] = term1 + term2
        p_table[n] = dp_curr
        dp_prev = dp_curr

    return p_table

def moments(tau):
    """
    Computes theoretical expected bytes and standard deviation for SampleInBall.
    E[N] = 8 + sum_{k=1}^tau (256 / (257 - k))
    Var[N] = sum_{k=1}^tau (256 * (k - 1) / ((257 - k)^2))
    """
    mean = 8.0 + sum(256.0 / (257 - k) for k in range(1, tau + 1))
    var = sum(256.0 * (k - 1) / ((257 - k) ** 2) for k in range(1, tau + 1))
    std = math.sqrt(var)
    return mean, std

def find_cutoffs(p_table, tau_list=[39, 49, 60]):
    bound_256 = Fraction(1, 2**256)
    results = {}
    for tau in tau_list:
        cutoff = None
        for n in sorted(p_table.keys()):
            prob = p_table[n][tau]
            if prob <= bound_256:
                cutoff = n
                break
        results[tau] = cutoff
    return results

def log2_fraction(frac):
    if frac == 0:
        return -float('inf')
    num = frac.numerator
    den = frac.denominator
    return math.log2(num) - math.log2(den)

def print_analysis():
    print("=" * 78)
    print("NIST FIPS 204 Appendix C: SampleInBall (Algorithm 29) Loop Bound Analysis")
    print("Failure Probability Requirement: <= 2^-256 (~8.636e-78)")
    print("=" * 78)
    
    tau_targets = [39, 49, 60]
    names = {39: "ML-DSA-44 (Category 2)", 49: "ML-DSA-65 (Category 3)", 60: "ML-DSA-87 (Category 5)"}
    
    p_table = compute_recurrence(tau_max=60, n_max=250)
    cutoffs = find_cutoffs(p_table, tau_targets)
    
    print("\n[1] Theoretical Moments & Cutoff Bounds:")
    print("-" * 78)
    print(f"{'Security Level':<24} | {'tau':<4} | {'Mean (E[N])':<11} | {'Std Dev':<8} | {'Cutoff (n)':<10} | {'Distance'}")
    print("-" * 78)
    for tau in tau_targets:
        m, s = moments(tau)
        c = cutoffs[tau]
        dist = (c - m) / s
        print(f"{names[tau]:<24} | {tau:<4} | {m:>8.2f} B  | {s:>6.2f} B | {c:>7} B  | {dist:>5.1f} sigma")
    print("-" * 78)
    print("Note: NIST Table 3 specifies unified minimum allowable limit = 221 bytes.")
    
    print("\n[2] Tail Probability Decay Around Cutoff (log2(P(n, tau))):")
    print("-" * 78)
    header = f"{'Bytes (n)':<10}"
    for tau in tau_targets:
        header += f" | tau={tau} (log2 P)"
    print(header)
    print("-" * 78)
    
    checkpoints = sorted(list(set(
        list(range(50, 60, 5)) +
        list(range(152, 160, 2)) +
        list(range(182, 190, 2)) +
        list(range(216, 226, 2))
    )))
    
    for n in checkpoints:
        row = f"{n:<10}"
        for tau in tau_targets:
            p = p_table[n][tau]
            log2_val = log2_fraction(p)
            if log2_val == -float('inf'):
                row += f" | {'-inf':>16}"
            else:
                row += f" | {log2_val:>16.2f}"
        print(row)
    print("-" * 78)
    
    print("\n[3] While Loop Rejection Limit (Step 8-10):")
    p_rej_max = Fraction(59, 256)
    n_while = math.ceil(-256.0 / (math.log2(59) - 8.0))
    p_while = p_rej_max ** n_while
    print(f"Max single-step rejection prob: (59/256) = {float(p_rej_max):.4f}")
    print(f"Minimum while iterations n for (59/256)^n <= 2^-256: n = {n_while}")
    print(f"log2((59/256)^{n_while}) = {log2_fraction(p_while):.2f} <= -256.0")
    print("=" * 78)

if __name__ == "__main__":
    print_analysis()
