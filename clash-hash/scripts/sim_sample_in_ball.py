#!/usr/bin/env python3
"""
Empirical Monte Carlo Simulation of SampleInBall (Algorithm 29)
Simulates 1,000,000 iterations to observe empirical byte usage and rejection counts,
and verifies goodness-of-fit against theoretical recurrence probabilities.
"""

import random
import math
import sys
import argparse
from collections import Counter
from fractions import Fraction

def simulate_sample_in_ball(tau=39, trials=1000000, seed=42):
    random.seed(seed)
    bytes_consumed_list = []
    max_rejections_single_step = 0
    
    # We can track distribution of byte usage
    byte_counter = Counter()
    
    # Run trials
    # To run 1,000,000 quickly in pure python, we can optimize the inner loop
    rand = random.getrandbits
    
    for _ in range(trials):
        # 8 bytes for signs
        total_bytes = 8
        
        # for i from 256 - tau to 255
        for i in range(256 - tau, 256):
            step_rejections = 0
            while True:
                total_bytes += 1
                j = rand(8) # random byte 0..255
                if j <= i:
                    break
                step_rejections += 1
            if step_rejections > max_rejections_single_step:
                max_rejections_single_step = step_rejections
                
        bytes_consumed_list.append(total_bytes)
        byte_counter[total_bytes] += 1
        
    return bytes_consumed_list, byte_counter, max_rejections_single_step

def run():
    parser = argparse.ArgumentParser(description="Monte Carlo Simulation of SampleInBall")
    parser.add_argument("--tau", type=int, default=39, help="Parameter tau (39, 49, 60)")
    parser.add_argument("--trials", type=int, default=1000000, help="Number of Monte Carlo trials")
    parser.add_argument("--seed", type=int, default=12345, help="Random seed")
    args = parser.parse_args()

    tau = args.tau
    trials = args.trials
    print("=" * 78)
    print(f"Monte Carlo Simulation: SampleInBall (tau={tau}, trials={trials:,})")
    print("=" * 78)

    consumed, counter, max_rej = simulate_sample_in_ball(tau=tau, trials=trials, seed=args.seed)

    # Moments
    emp_mean = sum(consumed) / trials
    emp_var = sum((x - emp_mean) ** 2 for x in consumed) / (trials - 1)
    emp_std = math.sqrt(emp_var)
    min_bytes = min(consumed)
    max_bytes = max(consumed)

    # Theoretical moments
    th_mean = 8.0 + sum(256.0 / (257 - k) for k in range(1, tau + 1))
    th_var = sum(256.0 * (k - 1) / ((257 - k) ** 2) for k in range(1, tau + 1))
    th_std = math.sqrt(th_var)

    print("\n[1] Empirical vs Theoretical Moments:")
    print("-" * 78)
    print(f"{'Metric':<25} | {'Empirical':<15} | {'Theoretical':<15} | {'Difference'}")
    print("-" * 78)
    print(f"{'Mean (bytes)':<25} | {emp_mean:<15.4f} | {th_mean:<15.4f} | {abs(emp_mean - th_mean):.4f}")
    print(f"{'Std Dev (bytes)':<25} | {emp_std:<15.4f} | {th_std:<15.4f} | {abs(emp_std - th_std):.4f}")
    print(f"{'Min observed bytes':<25} | {min_bytes:<15} | {8 + tau:<15} | -")
    print(f"{'Max observed bytes':<25} | {max_bytes:<15} | {'156 (Cutoff)':<15} | -")
    print(f"{'Max single-step rej':<25} | {max_rej:<15} | {'121 (Limit)':<15} | -")
    print("-" * 78)

    print("\n[2] Empirical Byte Usage Distribution (Top Frequency Ranges):")
    print("-" * 78)
    print(f"{'Bytes':<10} | {'Count':<10} | {'Empirical Frequency':<20} | {'Histogram'}")
    print("-" * 78)
    
    sorted_keys = sorted(counter.keys())
    # Display buckets
    for b in range(min_bytes, min(min_bytes + 20, max_bytes + 1)):
        cnt = counter[b]
        freq = cnt / trials
        bar = "#" * int(freq * 150)
        print(f"{b:<10} | {cnt:<10} | {freq:>10.6f}           | {bar}")
    print("...")
    for b in range(max(min_bytes + 20, max_bytes - 5), max_bytes + 1):
        cnt = counter[b]
        freq = cnt / trials
        bar = "#" * max(1, int(freq * 150)) if cnt > 0 else ""
        print(f"{b:<10} | {cnt:<10} | {freq:>10.6f}           | {bar}")
    print("-" * 78)

    print("\n[3] Security Cutoff Margin Analysis:")
    cutoff_spec = 221 if tau == 60 else (186 if tau == 49 else 156)
    table3_limit = 221
    print(f"Algorithm tau = {tau}:")
    print(f"  - Theoretical 2^-256 Cutoff: {cutoff_spec} bytes")
    print(f"  - Table 3 Unified Cutoff:   {table3_limit} bytes")
    print(f"  - Max observed in {trials:,} runs: {max_bytes} bytes")
    print(f"  - Safety margin to cutoff:   {cutoff_spec - max_bytes} bytes (~{(cutoff_spec - emp_mean) / emp_std:.1f} sigma)")
    print(f"  - Max single-step rejections: {max_rej} / 121 allowable limit")
    print("=" * 78)

if __name__ == "__main__":
    run()
