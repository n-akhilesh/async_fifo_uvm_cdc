# async_fifo_uvm_cdc

> **Asynchronous Dual-Clock FIFO with UVM-1.2 Testbench**  
> Industry-level CDC verification project — SKY130-compatible RTL, Gray-code pointers, 2-FF synchronizers, and a 25-file UVM environment.

---

## 📐 Design Specs

| Parameter     | Value                          |
|---------------|--------------------------------|
| Data Width    | 8-bit                          |
| FIFO Depth    | 16 entries                     |
| Write Clock   | 100 MHz                        |
| Read Clock    | 73 MHz (coprime — worst-case CDC)|
| Almost Full   | Threshold = 4 (depth − 4)      |
| Almost Empty  | Threshold = 4                  |
| Reset         | Active-low async (`arst_n`) — Qualcomm RDC pattern |
| Full Flag     | MSB XOR Gray-code (Cummings method) |

---

## 🗂️ Directory Structure

```
async_fifo_uvm_cdc/
├── rtl/
│   ├── async_fifo_top.sv        # Top-level integration
│   ├── fifo_mem.sv              # Dual-port SRAM behavioral model
│   ├── wptr_full.sv             # Write pointer + full/almost_full flags
│   ├── rptr_empty.sv            # Read pointer + empty/almost_empty flags
│   ├── sync_w2r.sv              # 2-FF write→read synchronizer
│   ├── sync_r2w.sv              # 2-FF read→write synchronizer
│   ├── rst_sync_wr.sv           # Write domain reset synchronizer
│   └── rst_sync_rd.sv           # Read domain reset synchronizer
├── tb/
│   └── fifo_assertions.sv       # SVA — overflow, underflow, gray validity
└── uvm/
    ├── fifo_if.sv               # Interface — wr_cb + rd_cb clocking blocks
    ├── fifo_pkg.sv              # Package — compilation order
    ├── fifo_seq_item.sv         # UVM Object — transaction (rand fields)
    ├── fifo_wr_driver.sv        # UVM Driver — write domain @ 100 MHz
    ├── fifo_rd_driver.sv        # UVM Driver — read domain @ 73 MHz
    ├── fifo_wr_monitor.sv       # UVM Monitor — write-side capture
    ├── fifo_rd_monitor.sv       # UVM Monitor — read-side capture
    ├── fifo_scoreboard.sv       # UVM Scoreboard — golden FIFO queue
    ├── fifo_coverage.sv         # UVM Subscriber — 7 covergroups
    ├── fifo_agent_wr.sv         # UVM Agent — write domain (ACTIVE)
    ├── fifo_agent_rd.sv         # UVM Agent — read domain (ACTIVE)
    ├── fifo_env.sv              # UVM Env — wires all analysis ports
    ├── fifo_base_test.sv        # UVM Test — factory + run_phase
    └── sequences/
        ├── fifo_wr_basic_seq.sv
        ├── fifo_rd_basic_seq.sv
        ├── fifo_fill_seq.sv
        ├── fifo_drain_seq.sv
        ├── fifo_overflow_seq.sv
        ├── fifo_underflow_seq.sv
        ├── fifo_almost_full_seq.sv
        ├── fifo_almost_empty_seq.sv
        ├── fifo_reset_seq.sv
        ├── fifo_simultaneous_rw_seq.sv
        ├── fifo_burst_wr_seq.sv
        └── fifo_burst_rd_seq.sv
```

---

## 🔑 RTL Architecture

```
              wr_clk domain                     rd_clk domain
  ┌──────────────────────────┐     ┌──────────────────────────────┐
  │  rst_sync_wr             │     │  rst_sync_rd                 │
  │  wptr_full  ──wptr_gray──┼─────┼──sync_w2r──► rptr_empty      │
  │             ◄─rptr_gray──┼─────┼──sync_r2w──  rptr_empty      │
  │  fifo_mem (dual-port)    │     │                              │
  └──────────────────────────┘     └──────────────────────────────┘
```

- **Gray-code pointers** cross clock domains via 2-FF synchronizers
- **Full flag** — MSB XOR method (WPTR[N] ≠ RPTR[N], lower bits equal)
- **Empty flag** — all bits equal after synchronization

---

## ✅ Test Cases (12 Sequences)

| # | Sequence                  | Coverage Goal                         |
|---|---------------------------|---------------------------------------|
| 1 | `fifo_wr_basic_seq`       | 32 random writes                      |
| 2 | `fifo_rd_basic_seq`       | 32 random reads                       |
| 3 | `fifo_fill_seq`           | Fill to depth=16 → verify `full`      |
| 4 | `fifo_drain_seq`          | Drain completely → verify `empty`     |
| 5 | `fifo_overflow_seq`       | Write when full → SVA assertion fires |
| 6 | `fifo_underflow_seq`      | Read when empty → SVA assertion fires |
| 7 | `fifo_almost_full_seq`    | Fill to AF_THRESH=12                  |
| 8 | `fifo_almost_empty_seq`   | Drain to AE_THRESH=4                  |
| 9 | `fifo_reset_seq`          | Mid-operation reset → verify clear    |
|10 | `fifo_simultaneous_rw_seq`| CDC stress — concurrent R+W           |
|11 | `fifo_burst_wr_seq`       | 16 back-to-back writes                |
|12 | `fifo_burst_rd_seq`       | 16 back-to-back reads                 |

---

## 🚀 Quick Start

```bash
# Compile (VCS example)
vcs -sverilog -ntb_opts uvm-1.2 \
    rtl/*.sv tb/*.sv uvm/*.sv uvm/sequences/*.sv \
    -o simv

# Run a test
./simv +UVM_TESTNAME=fifo_base_test +UVM_VERBOSITY=UVM_MEDIUM
```

---

## 📌 Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/):
`feat`, `fix`, `chore`, `test`, `docs`, `refactor`

---

## 📎 Related Projects

- [`2stage_opamp`](../2stage_opamp) — 2-Stage CMOS OPAMP with Miller compensation
- [`buck_boost_converter`](../buck_boost_converter) — Analog PWM Buck-Boost converter

---

*Designed and verified using SystemVerilog / UVM-1.2 — SKY130 compatible RTL.*
