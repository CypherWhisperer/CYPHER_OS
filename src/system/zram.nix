# ──────────────────────────────────────────────────────────────────────────────
# src/system/zram.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # ZRAM
  # ────────────────────────────────────────────────────────────────────────────
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
  # with acceptable CPU overhead. On your i7-7th gen the decompression cost
  # is negligible compared to a disk read.
  # ────────────────────────────────────────────────────────────────────────────
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    #priority = 999;
  };
}
