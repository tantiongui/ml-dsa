#!/usr/bin/env python3
"""
Minimalist & Clean Hardware RTL Sampling Distribution Plot
NIST FIPS 204 SampleInBall (tau = 39, ML-DSA-44)
"""

from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# 1. Hardware RTL Simulation Data (10,000 trials from Clash Mealy FSM)
bytes_data = [47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60]
counts = [476, 1407, 1988, 2166, 1658, 1152, 591, 338, 123, 71, 19, 9, 1, 1]
total_trials = 10000
frequencies = [c / total_trials * 100 for c in counts]

mean_bytes = sum(b * c for b, c in zip(bytes_data, counts)) / total_trials

# 2. Minimalist Clean Plotting
fig, ax = plt.subplots(figsize=(10, 5.5), dpi=300)

# Bar chart with clean styling
bars = ax.bar(bytes_data, frequencies, color='#2563eb', width=0.72, edgecolor='none', alpha=0.88, label='Hardware RTL (10,000 trials)')

# Display percentages on top of major bars
for b, freq in zip(bytes_data, frequencies):
    if freq >= 1.0:
        ax.text(b, freq + 0.35, f"{freq:.1f}%", ha='center', va='bottom', fontsize=9.5, fontweight='bold', color='#1e293b')

# Mean line
ax.axvline(x=mean_bytes, color='#dc2626', linestyle='--', linewidth=1.8, label=f'Mean = {mean_bytes:.2f} B')

# Aesthetic & Clean Layout
ax.set_title('SampleInBall: Hardware RTL Probability Distribution (tau = 39)', fontsize=13.5, fontweight='bold', pad=14, color='#0f172a')
ax.set_xlabel('Bytes Consumed from Stream', fontsize=11, fontweight='bold', color='#1e293b')
ax.set_ylabel('Probability (%)', fontsize=11, fontweight='bold', color='#1e293b')

ax.set_xticks(bytes_data)
ax.set_xlim(46.2, 60.8)
ax.set_ylim(0, 25.5)

# Subtle grid only on Y-axis
ax.yaxis.grid(True, linestyle='--', alpha=0.4, color='#cbd5e1')
ax.xaxis.grid(False)

# Clean spines (hide top and right)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_color('#cbd5e1')
ax.spines['bottom'].set_color('#cbd5e1')

ax.legend(loc='upper right', frameon=True, framealpha=0.9, fontsize=10)

plt.tight_layout()

# Save output
project_root = Path(__file__).resolve().parents[2]
output_misc = project_root / 'misc' / 'hw_distribution_clean.png'
output_artifact = Path('/home/a0/.gemini/antigravity/brain/4a19bb87-5f6e-4f7f-8af5-459625eb9953/hw_distribution_clean.png')

plt.savefig(output_misc, dpi=300)
if output_artifact.parent.exists():
    plt.savefig(output_artifact, dpi=300)
print(f"Generated clean plot successfully:")
print(f"  {output_misc}")
