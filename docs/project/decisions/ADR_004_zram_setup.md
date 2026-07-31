# ADR-004: ZRAM Setup

**Date:** 2026-04-15
**Status:** Accepted
**Deciders:** CypherWhisperer
**Related:** [INC-2026-04-15-001](../../development/incidents/INC_2026_04_15_001.md), [ADR-003 — Swap Activation](ADR_003_swap_activation.md)

---

## Context

With the disk swapfile now activated ([ADR-003](ADR_003_swap_activation.md)), the machine had a fallback for memory pressure. But disk swap is slow — _writing pages to the SSD under pressure is orders of magnitude slower than keeping them in RAM._ On a machine running GNOME (_~2GB baseline_) and performing memory-hungry Nix builds, the goal was to absorb as much pressure as possible in RAM before the kernel reaches for the disk at all.

ZRAM is the standard answer to this problem. NixOS has first-class support via the `zramSwap` option. The configuration decision is which algorithm and how much RAM to allocate.

---

## Decision

Enable ZRAM swap using `zstd` compression at 50% of total RAM.

---

## Reasoning

**What ZRAM does:**

ZRAM creates a compressed in-memory block device that the kernel treats as a high-priority swap device. Under memory pressure, pages are compressed and kept in RAM rather than written to the disk swapfile. Reads and writes happen at RAM speed — _the only cost is CPU time for compression and decompression, which on modern hardware is negligible compared to a disk access_.

The kernel assigns ZRAM a higher swap priority than the disk swapfile automatically. No manual priority configuration is needed.

**Swap hierarchy after this change:**
```
RAM (free)
  ↓ pressure
ZRAM /dev/zram0 — compressed RAM, fast, high priority
  ↓ ZRAM full
/swap/swapfile  — disk-backed, slow, last resort
```

**`memoryPercent = 50`:**

This controls how much of total RAM ZRAM may use _before_ compression. On my machine (_8GB RAM_), 50% = 4GB of uncompressed input. With `zstd` typically achieving 2:1 to 3:1 compression ratios, the actual RAM consumed by the ZRAM device is roughly 1.5–2GB — and it provides approximately 8–12GB of effective swap headroom before the disk swapfile is touched.

50% is a conservative starting point. It leaves 4GB of raw RAM headroom above the ZRAM allocation, which is appropriate for a machine running a DE and active builds simultaneously.

**`algorithm = "zstd"`:**

`zstd` offers better compression ratios than `lz4` (_the other common choice_) with acceptable CPU overhead. On a 7th-gen i7, the decompression cost is negligible compared to a disk read. `lz4` is faster to compress/decompress but leaves more data uncompressed at a given RAM budget — _it is the right call on very CPU-constrained systems._ `zstd` is the right call here.

**The NixOS configuration:**

```nix
# ─────────────────────────────────────────────────────────────────────────────
# ZRAM
# ─────────────────────────────────────────────────────────────────────────────
# Creates a compressed in-memory swap device. Sits in front of the disk
# swapfile in the kernel's swap priority hierarchy — memory pressure hits
# ZRAM first, disk swapfile only if ZRAM fills up.
#
# memoryPercent: how much of total RAM ZRAM may use BEFORE compression.
# At 50% on 8GB = 4GB uncompressed input. With zstd typically achieving
# 2:1 to 3:1 compression, that's effectively 8-12GB of swap headroom
# before the disk swapfile is touched.
#
# algorithm: zstd is the best default — better compression ratio than lz4
# with acceptable CPU overhead.
zramSwap = {
  enable        = true;
  memoryPercent = 50;
  algorithm     = "zstd";
};
```

**Verification after applying:**

```bash
# Should show two swap devices — zram0 and the swapfile
swapon --show

# Expected output:
# NAME       TYPE      SIZE  USED PRIO
# /dev/zram0 partition   4G    0B  100   ← high priority, RAM-backed
# /swap/swapfile file   10G    0B   -2   ← low priority, disk-backed
```

**ZRAM is per-OS:**

ZRAM is a kernel-level construct configured by each OS's init system independently. RAM is not a shared resource across boots — _only one OS is ever live at a time, and that OS configures its own ZRAM._ This is the correct behavior.

---

## Alternatives Considered

### ZSWAP instead of ZRAM

ZSWAP is a kernel-level write-back cache that sits _in front of_ the disk swap device. It compresses pages in RAM before they get written to disk — deferred, batched disk writes rather than immediate ones. It reduces disk I/O but disk writes still happen.

ZRAM is fundamentally different: compressed RAM _is_ the swap device. No disk writes for anything that fits in ZRAM. For this workload (builds under memory pressure), avoiding disk writes entirely is the goal. ZRAM wins.

ZSWAP and ZRAM can technically coexist — ZRAM as a high-priority swap device, ZSWAP in front of the disk swapfile as a secondary layer. The added complexity is not justified here. ZRAM alone is sufficient.

### Higher `memoryPercent` (75% or 100%)

Higher allocation gives more swap headroom before disk is touched, at the cost of leaving less headroom for actual active processes. On a machine where GNOME + a build can consume 6–7GB of active RAM, 75% ZRAM (_6GB raw input_) would leave only 2GB of headroom above the ZRAM allocation for active processes — _too aggressive._ 50% is the right balance for this workload.

### Lower `memoryPercent` (25%)

Less aggressive, but with `zstd` at 25% you only get 2GB of uncompressed input, giving ~4–6GB of effective headroom. Not meaningfully better than just having the disk swapfile. 50% provides a substantially larger buffer for little additional cost.

---

## Consequences

**Positive:**

- Memory pressure now hits compressed RAM first. Builds that would previously have crashed the terminal now run slower but don't crash — the kernel drains ZRAM before reaching for the disk.
- Zero disk writes for anything that fits in the ZRAM device. No additional SSD wear for normal memory pressure scenarios.
- NixOS manages ZRAM configuration declaratively. No manual setup on fresh installs.

**Negative / Trade-offs:**

- ZRAM consumes some RAM for the compressed pages. At 50% allocation with typical content, the overhead is ~1.5–2GB. On an 8GB machine this is acceptable.
- CPU cost for compression/decompression on every page swap. Negligible on a 7th-gen i7 but worth noting for extremely CPU-constrained scenarios.

**Neutral / Operational:**

- The `memoryPercent` value should be revisited if the machine gets a RAM upgrade. On 16GB, 50% still works well. On 32GB+, reducing the percentage may be worth considering since raw RAM abundance changes the pressure dynamics.
- Each OS in the fleet configures its own ZRAM independently, since it is a per-boot kernel construct.
