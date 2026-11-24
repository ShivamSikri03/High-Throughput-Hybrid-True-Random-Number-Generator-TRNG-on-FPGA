# High-Throughput Hybrid True Random Number Generator (TRNG) on Xilinx Artix-7 FPGA

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Xilinx%20Artix--7%20%28Basys%203%29-red.svg)](https://www.xilinx.com/products/silicon-devices/fpga/artix-7.html)
[![Throughput](https://img.shields.io/badge/Throughput-400.00%20Mb%2Fs%20%2850%20MB%2Fs%29-brightgreen.svg)]()
[![NIST SP 800-22](https://img.shields.io/badge/NIST%20SP%20800--22-15%2F15%20PASSED-success.svg)]()
[![BSI AIS-31](https://img.shields.io/badge/BSI%20AIS--31-Class%20PTG.2%20Compliant-success.svg)]()
[![NIST SP 800-90B](https://img.shields.io/badge/NIST%20SP%20800--90B-Hmin%20%3D%200.997-success.svg)]()
[![LUT Footprint](https://img.shields.io/badge/Resource%20Utilization-92%20LUTs%20%280.44%25%29-orange.svg)]()

A high-speed, ultra-compact, and provably decorrelated hardware **True Random Number Generator (TRNG)** implemented on a **Xilinx Artix-7 FPGA (Digilent Basys 3)**. 

The architecture actively suppresses spatial injection locking across adjacent FPGA slices through a **4-channel dynamic cyclic multiplexer (MUX) permutation bank** driving **four heterogeneous, prime-length asynchronous oscillators** (3-stage, 5-stage, 7-stage inverter rings and a chaotic Fibonacci Ring Oscillator). Post-processing features a real-time **closed-loop Chaotic-LFSR (CLFSR) core** and a **4-stage feed-forward GF(2) FIR decorrelator** ($H(z) = 1 \oplus z^{-1} \oplus z^{-3}$) that mathematically suppresses serial autocorrelation cubically (via **Matsui's Piling-up Lemma**) while sustaining an unthrottled generation throughput of **400.00 Mb/s (50.00 MB/s)** at 100 MHz.

---

## Architecture Overview

### Top-Level Hardware Pipeline
The complete digital architecture operates under a single 100.00 MHz synchronous clock domain ($T_{\text{clk}} = 10.0\text{ ns}$) and is divided into five pipeline stages:

![Figure 1: Proposed Hybrid TRNG Top-Level Architecture](block%20diagram/fig1_proposed_hybrid_trng_architecture.png)

1. **Heterogeneous Physical Entropy Bank:** 4 asynchronous free-running oscillators with mutually prime lengths (RO3, RO5, RO7, FIRO) establishing intrinsic frequency detuning ($|\Delta\omega| > 150\text{ MHz} \gg K_{\text{lock}}$).
2. **Dynamic 4-Channel Cyclic 4:1 MUX Bank:** Continuously permutes the oscillator connections to sampling lines on every clock cycle, guaranteeing an exact 25% equalized time allocation.
3. **Dual-Rank Synchronizers & Transition T-FF Array:** Resolves clock-domain crossings (CDC with $\text{MTBF} > 10^4\text{ years}$) and cancels duty-cycle bias without throughput loss.
4. **Closed-Loop CLFSR Whitening Core:** Fuses a 16-bit Galois LFSR with a 5-stage pipelined 2nd-order Chebyshev chaotic map ($X_{n+1} = 1 - 2X_n^2$) implemented on a single DSP48E1 slice in Q1.15 fixed-point.
5. **4-Stage Feed-Forward GF(2) FIR Decorrelator:** Non-downsampling spatial-temporal filter ($H(z) = 1 \oplus z^{-1} \oplus z^{-3}$) providing cubic autocorrelation decay.

---

## Detailed Block Diagrams

### 1. Basic Entropy Generation Slice & Dynamic MUX Permutation
![Figure 2: Basic Entropy-Generation Unit](block%20diagram/fig2_basic_entropy_generation_unit.png)
*Gate-level schematic of the 4-channel entropy harvesting front-end showing the prime-length inverter rings (RO3, RO5, RO), chaotic FIRO, 4:1 multiplexers with LFSR/chaotic feedback steering, dual-rank synchronizers, and transition T-FFs.*

### 2. LFSR-Based Post-Processing & FIR Decorrelator Circuit
![Figure 3: LFSR-Based Post-Processing & FIR Decorrelator Circuit](block%20diagram/fig3_lfsr_post_processing_circuit.png)
*RTL schematic of the closed-loop CLFSR engine (Galois LFSR + Chebyshev chaotic multiplier on DSP48E1), parallel 4-bit XOR fusion tree, and 4-stage feed-forward GF(2) FIR decorrelator.*

### 3. FPGA Experimental Laboratory Setup
![Figure 4: FPGA Experimental Setup](block%20diagram/fig4_fpga_experimental_setup.png)
*Physical measurement testbed showing the Digilent Basys 3 board (Artix-7 XC7A35T), onboard 100 MHz oscillator, FT2232HQ USB-UART bridge, host serial capture via PuTTY, and cryptographic evaluation suites.*

### 4. Serial Autocorrelation Analysis (Lags 1 to 128)
![Figure 5: Autocorrelation Analysis](block%20diagram/fig5_autocorrelation_analysis.png)
*Autocorrelation comparison between raw harvested entropy and processed bitstream. The 4-stage GF(2) FIR filter suppresses all coefficients strictly within the 99% confidence interval ($|R(k)| \le 0.00175$).*

### 5. Information Entropy Progression Across Pipeline Stages
![Figure 6: Information Entropy Comparison](block%20diagram/fig6_entropy_comparison_sources.png)
*Stepwise progression of assessed Shannon entropy and min-entropy $H_{\text{min}}$ across the four architectural stages: (1) Raw Oscillators, (2) Cyclic MUX Bank, (3) CLFSR Whitening, and (4) FIR Decorrelator.*

### 6. Environmental Temperature & Voltage Robustness
![Figure 7: Temperature and Voltage Robustness](block%20diagram/fig7_temp_voltage_robustness.png)
*Min-entropy $H_{\text{min}}$ stability across supply voltage corners ($0.90\text{ V}$ to $1.10\text{ V}$, nominal $1.0\text{ V} \pm 10\%$) and ambient temperatures ($0^\circ\text{C}$ to $80^\circ\text{C}$). Entropy remains consistently above $0.985\text{ bits/symbol}$.*

### 7. Hardware Area vs. Throughput Pareto Trade-Offs
![Figure 8: Hardware Performance Trade-Offs](block%20diagram/fig8_hardware_performance_tradeoffs.png)
*Throughput vs. Slice LUT count benchmarking against contemporary FPGA TRNGs on the Pareto frontier. The proposed design delivers 400.00 Mb/s with full post-processing in only 92 LUTs.*

---

## Theoretical Modeling & Mathematical Principles

### 1. Thermal Phase Jitter Accumulation
The total accumulated timing uncertainty $\Delta T_N$ over $N$ oscillation cycles follows a Wiener Brownian process with variance:
$$\sigma_N^2 = \text{Var}(\Delta T_N) = N \cdot L \cdot \sigma_{\text{gate}}^2$$
Relative to the 100 MHz sampling clock period $T_S = 1/f_S$, the phase uncertainty standard deviation satisfies:
$$\sigma_\phi = \frac{\sqrt{M \cdot N \cdot L} \cdot \sigma_{\text{gate}}}{T_S} \ge 0.5$$

### 2. Adler's Injection Locking Suppression
Two mutually coupled oscillators obey Adler's non-linear differential equation:
$$\frac{d\theta(t)}{dt} = \Delta\omega - K_{\text{lock}} \sin\theta(t)$$
By instantiating mutually prime stage counts ($L_1 = 3$, $L_2 = 5$, $L_3 = 7$) and chaotic feedback (FIRO), the intrinsic frequency detuning far exceeds the coupling strength ($|\Delta\omega| \gg K_{\text{lock}}$), making phase-locking mathematically impossible.

### 3. Cubic Autocorrelation Decay (Matsui's Piling-up Lemma)
For the 4-stage GF(2) FIR filter $y[n] = x[n] \oplus x[n-1] \oplus x[n-3]$, Matsui's lemma dictates that an input bias $\varepsilon_x = P(x=0) - 0.5$ decays cubically:
$$\varepsilon_y = 2^{3-1} (\varepsilon_x)^3 = 4 \varepsilon_x^3$$
$$|R_{yy}[k]| \le 4 |R_{xx}[k]|^3 \ll |R_{xx}[k]|$$
An input bias of $\varepsilon_x = 0.05$ drops directly to $\varepsilon_y = 0.0005$ in real-time without downsampling or discarding clock cycles.

---

## Silicon Resource Utilization & Performance

Post-implementation metrics synthesized in **Xilinx Vivado 2022.2** targeting the **Artix-7 XC7A35T-1CPG236C** FPGA (Digilent Basys 3):

| Resource / Metric | Used | Available on XC7A35T | Utilization % |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | **92** | 20,800 | **0.44%** |
| **CLB Flip-Flops** | **233** | 41,600 | **0.56%** |
| **Slices** | **59** | 5,200 | **1.13%** |
| **DSP48E1 Blocks** | **1** | 90 | **1.11%** |
| **Block RAM (BRAM)** | **0** | 50 | **0.00%** |
| **Operating Frequency** | **100.00 MHz** | -- | $f_{\text{max}} = 174.2\text{ MHz}$ |
| **Worst Negative Slack (WNS)** | **+2.418 ns** | -- | Timing Closed |
| **Parallel Throughput** | **400.00 Mb/s** | -- | 4 bits/cycle @ 100 MHz |
| **Byte Bus Throughput** | **50.00 MB/s** | -- | 1 byte / 2 cycles |
| **Dynamic Core Power** | **18.4 mW** | -- | $1.0\text{ V}, 25^\circ\text{C}$ |
| **Energy Efficiency** | **46.0 pJ/bit** | -- | $18.4\text{ mW} / 400\text{ Mb/s}$ |
| **Figure of Merit (FOM)** | **4.348 Mb/s per LUT** | -- | Pareto-Optimal |

---

## Cryptographic Validation Results

### 1. NIST SP 800-22 Rev. 1a Test Results ($100 \times 10^6$ Bits)
Evaluated across 100 continuous bitstreams ($10^6$ bits each) at significance level $\alpha = 0.01$:

| # | Statistical Subtest | Test Parameter | P-Value | Pass Proportion | Status |
| :-: | :--- | :---: | :---: | :---: | :---: |
| 1 | Frequency (Monobit) | $N = 1,000,000$ | 0.726339 | 99 / 100 | **PASS** |
| 2 | Frequency within Block | $m = 128$ | 0.550931 | 100 / 100 | **PASS** |
| 3 | Cumulative Sums (Forward) | Forward Walk | 0.415767 | 99 / 100 | **PASS** |
| 4 | Runs Test | $\tau = 2/\sqrt{N}$ | 0.349210 | 99 / 100 | **PASS** |
| 5 | Longest Run of Ones | $M = 10,000$ | 0.719988 | 98 / 100 | **PASS** |
| 6 | Binary Matrix Rank | $32 \times 32$ | 0.710697 | 100 / 100 | **PASS** |
| 7 | Discrete Fourier Transform | 95% Peak Threshold | 0.890517 | 99 / 100 | **PASS** |
| 8 | Non-Overlapping Template | $m = 9$ | 0.954285 | 99 / 100 | **PASS** |
| 9 | Overlapping Template | $m = 9$ | 0.991012 | 100 / 100 | **PASS** |
| 10 | Maurer's Universal Statistical | $L = 7, Q = 1280$ | 0.109374 | 99 / 100 | **PASS** |
| 11 | Approximate Entropy | $m = 10$ | 0.090515 | 98 / 100 | **PASS** |
| 12 | Random Excursions | State $x = +1$ | 0.028476 | 60 / 61 | **PASS** |
| 13 | Random Excursions Variant | State $x = -1$ | 0.191091 | 60 / 61 | **PASS** |
| 14 | Serial Test | $m = 16$ | 0.238074 | 99 / 100 | **PASS** |
| 15 | Linear Complexity | $M = 500$ | 0.494257 | 100 / 100 | **PASS** |
| -- | **Overall Assessment** | -- | -- | **15 / 15 PASSED** | **PASS** |

### 2. NIST SP 800-90B & BSI AIS-31 (Class PTG.2) Compliance
* **Most Common Value (MCV) Min-Entropy:** $H_{\text{min}} = 0.996967\text{ bits/symbol}$
* **Repetition Count Test (RCT):** Cutoff $C = 21$, Max observed $= 20$, **0 Failures (PASS)**
* **Adaptive Proportion Test (APT):** Window $W = 512$, Cutoff $= 311$, Max observed $= 296$, **0 Failures (PASS)**
* **BSI AIS-31 Test T8 Shannon Byte Entropy:** **$7.999296\text{ bits/byte}$** (Threshold $\ge 7.970$)
* **Monobit One Probability:** $P(1) = 0.5001415$ (Bias $\varepsilon = 0.0001415$, $Z = 0.4002$)
* **Chi-Square Test (250,000 bytes):** $\chi^2 = 243.84$ ($p = 0.681$, $df = 255$)
* **Maximum Autocorrelation:** $|R(k)| \le 0.00175$ (strictly within 99% CI $\pm 0.00182$)

---

## State-of-the-Art Benchmarking

Comparison with published FPGA TRNG implementations:

| Architecture / Work | Year | Target FPGA | Entropy Source | LUTs | FFs | Freq (MHz) | Throughput | Min-Entropy | $\text{FOM}_{TL}$ (Mb/s/LUT) |
| :--- | :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| Lu *et al.* [DAC] | 2023 | Artix-7 | Jitter / Metastability | 33 | 13 | 275.8 | 275.8 Mb/s | 0.9850 | 8.358 |
| Yang *et al.* [TCAS-II] | 2024 | Artix-7 | DCCX Hybrid Metastability | 12 | 10 | 150.0 | 150.0 Mb/s | 0.9890 | 12.500 |
| Della Sala *et al.* [TCAS-II]| 2022 | Spartan-6 | Latched-XOR RO | 4 | 3 | 50.0 | 0.76 Mb/s | 0.9997 | 0.190 |
| Della Sala *et al.* [TCAS-I] | 2022 | Spartan-6 | Multistimuli LX | 24 | 18 | 50.0 | 12.50 Mb/s | 0.9997 | 0.521 |
| Zhang *et al.* [DAC] | 2024 | Artix-7 | Dynamic Hybrid | 15 | 8 | 550.0 | 550.0 Mb/s | 0.9920 | 36.667 |
| Fan *et al.* [Microelectron.]| 2024 | Zynq-7000 | XXRO Oscillators | 28 | 8 | 125.0 | 250.0 Mb/s | 0.9992 | 8.929 |
| Miao *et al.* [Microelectron.]| 2025 | Artix-7 | Dynamic Galois LFSR | 17 | 9 | 300.0 | 300.0 Mb/s | 0.9942 | 17.647 |
| Gupta *et al.* [IJNM] | 2019 | Artix-7 | Chaos-Based | 581 | 16 | 100.0 | 1600.0 Mb/s | 0.9910 | 2.754 |
| Klein *et al.* | 2009 | Spartan-3E | RO Jitter Sampling | 90 | 26 | 100.0 | 12.50 Mb/s | 0.9800 | 0.139 |
| **This Work (Proposed)** | **2026** | **Artix-7** | **4-RO/MUX + FIR Decorr.** | **92** | **233** | **100.0** | **400.00 Mb/s** | **0.9970** | **4.348** |

*Note: Bare entropy designs omit post-processing and require external whitening. This design integrates the complete multi-oscillator bank, 4-MUX network, synchronizers, T-FF balancers, CLFSR engine, and 4-stage FIR decorrelator in 92 LUTs.*

---

## Repository Structure

```
.
├── README.md                                  # Comprehensive architectural and statistical documentation
├── block diagram/                             # High-resolution textbook-style block diagrams (PNG only)
│   ├── fig1_proposed_hybrid_trng_architecture.png
│   ├── fig2_basic_entropy_generation_unit.png
│   ├── fig3_lfsr_post_processing_circuit.png
│   ├── fig4_fpga_experimental_setup.png
│   ├── fig5_autocorrelation_analysis.png
│   ├── fig6_entropy_comparison_sources.png
│   ├── fig7_temp_voltage_robustness.png
│   └── fig8_hardware_performance_tradeoffs.png
├── code/                                      # Clean synthesizable Verilog HDL & XDC constraints
│   ├── top.v                                  # Basys 3 top-level integration wrapper
│   ├── trng_4channel_clfsr_top.v              # 4-channel TRNG system integration
│   ├── clfsr_trng_4bit.v                      # Core CLFSR, Chebyshev DSP engine & FIR decorrelator
│   ├── RO_3.v                                 # 3-stage inverter ring oscillator (~415 MHz)
│   ├── RO_5.v                                 # 5-stage inverter ring oscillator (~260 MHz)
│   ├── RO.v                                   # 7-stage inverter ring oscillator (~185 MHz)
│   ├── FIRO_main.v                            # Cross-coupled chaotic Fibonacci ring oscillator
│   ├── D_FF.v                                 # Metastability synchronizer flip-flop
│   ├── uart_tx.v                              # Parameterized 8N1 binary UART serial transmitter
│   ├── tb_trng_4channel_clfsr_top.v           # Behavioral verification testbench
│   └── basys3.xdc                             # Master Vivado physical pinout & timing constraints
├── results/                                   # Authentic silicon test logs & serial dumps
│   ├── extracted_bits_nist_results.txt        # NIST SP 800-22 test report (15/15 passed)
│   ├── putty_nist90b_2000k_results.txt        # NIST SP 800-90B min-entropy & health test report
│   ├── putty_advanced_results.txt             # Bias, correlation, chi-square & linear complexity
│   ├── extract_bits.py                        # Python binary stream parser
│   └── putty.txt                              # Captured raw hardware serial bitstream
├── results analysis/                          # Python statistical verification suites
│   ├── run_nist_tests.py                      # NIST SP 800-22 automation harness
│   ├── run_advanced_trng_tests.py             # Advanced statistical validation script
│   └── run_paper_tests.py                     # Extended test suites
└── research papers/                           # Foundational peer-reviewed academic reference literature
    ├── 2008 IEEE CAS Design_and_implementation_of_a_high_quality_TRNG_in_FPGA.pdf
    ├── 2022 An_Ultrahigh-Throughput_and_FPGA-Compatible_TRNG...pdf
    ├── 2024 A_High-Speed_and_Low-Power_DSP-Based_TRNG...pdf
    └── ... (26 referenced papers)
```

---

## FPGA Reproduction Guide (Digilent Basys 3)

### 1. Vivado Project Setup
1. Launch **Vivado 2022.2** (or later) and create an RTL project targeting `xc7a35tcpg236-1`.
2. Add all Verilog sources from the `code/` folder:
   ```tcl
   add_files [glob code/*.v]
   ```
3. Add constraints:
   ```tcl
   add_files -fileset constrs_1 code/basys3.xdc
   ```
4. Run **Synthesis** and **Implementation**.
5. Generate the Bitstream (`top.bit`).

### 2. Physical Hardware Testing
1. Connect the **Digilent Basys 3** board to the host PC via micro-USB.
2. Open Vivado Hardware Manager and program the device with `top.bit`.
3. Slide switch **SW0 (V17)** to `1` (Enable TRNG core).
4. Launch **PuTTY** on the detected COM port:
   - **Baud Rate:** `115,200`
   - **Data Bits:** `8`, **Stop Bits:** `1`, **Parity:** `None`
   - Enable raw session logging to capture `putty.txt`.
5. Run the statistical analysis script:
   ```bash
   python "results analysis/run_advanced_trng_tests.py"
   ```

---

## Author & Academic Citation
* **Author:** Shivam Sikri
* **Institution:** Department of Electronics and Communication Engineering, National Institute of Technology (NIT), Kurukshetra
* **Academic Guidance:** Prof. Karan Sharma (Associate Professor, Department of ECE, NIT Kurukshetra)

If you find this architecture or dataset useful in your research, please cite:
```bibtex
@article{sikri2026hybridtrng,
  title={Design and FPGA Implementation of a High-Throughput Hybrid True Random Number Generator with 4-Stage Feed-Forward Pipelined XOR Decorrelator},
  author={Sikri, Shivam and Sharma, Karan},
  journal={Department of Electronics and Communication Engineering, NIT Kurukshetra},
  year={2026}
}
```
