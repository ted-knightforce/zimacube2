# ZimaCube 2 Pioneer Build — Phase 1: Storage Benchmark

**Author:** ted-knight  
**Date:** May 23, 2026  
**Program:** ZimaCube 2 Pioneer Program  
**Hardware:** ZimaCube 2 Standard

---

## Overview

This document covers the Phase 1 storage benchmarks for my ZimaCube 2 Pioneer Program build. The goal was to establish baseline performance metrics for two distinct storage tiers before moving into Phase 2 (Media Server) and Phase 4 (AI/Ollama inference).

The benchmarks compare:
- **Glacier** — ZFS RAIDZ1 pool across 4× 2TB PCIe 4.0 NVMe SSDs via OCuLink (external Aoostar TB4S-OC enclosure)
- **Arctic-Storage** — btrfs single 2TB PCIe 5.0 NVMe SSD in ZimaCube 2's internal 7th Bay slot

---

## Hardware Configuration

### ZimaCube 2 Standard

| Component | Specification |
|---|---|
| CPU | Intel Core i3-1215U (12th Gen, 6-core) |
| RAM | 16GB DDR5 |
| OS Drive | Kingston OM8PGP4 256GB NVMe (nvme5n1) |
| OS | ZimaOS (Buildroot-based, immutable) |
| PCIe Slot 1 | OCuLink SFF-8612 adapter card |
| 7th Bay Slot 1 | Crucial P510 2TB PCIe 5.0 NVMe |

### Glacier Pool — External Enclosure

| Component | Specification |
|---|---|
| Enclosure | Aoostar TB4S-OC |
| Connection | OCuLink via PCIe 4.0 x4 (Slot 1) |
| Chip | ASM2462PDX |
| Bandwidth per slot | 800 MB/s (PCIe 3.0 x1 per slot) |
| Total bandwidth | ~3,200 MB/s (4 slots combined, theoretical max) |
| Drive × 2 | ORICO 2TB NVMe PCIe 4.0 |
| Drive × 2 | XPG GAMMIX S70 BLADE 2TB PCIe 4.0 |
| Filesystem | ZFS RAIDZ1 |
| Pool name | glacier |
| Mount point | /media/glacier |
| Usable capacity | ~5.5TB |

### Arctic-Storage — Internal 7th Bay

| Component | Specification |
|---|---|
| Drive | Crucial P510 2TB PCIe 5.0 NVMe |
| Connection | Internal 7th Bay (ZimaCube 2 Standard) |
| Bandwidth cap | 800 MB/s total (7th Bay ASMedia bridge) |
| Filesystem | btrfs |
| Mount point | /media/Arctic-Storage |
| Usable capacity | ~1.8TB |

---

## ZFS Pool Configuration

The glacier pool was created with the following parameters:

```bash
zpool create -f \
  -m /media/glacier \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  glacier raidz1 \
  /dev/nvme1n1 \
  /dev/nvme2n1 \
  /dev/nvme3n1 \
  /dev/nvme4n1
```

### ZFS Datasets

```
glacier            /media/glacier
glacier/VM         /media/glacier/VM
glacier/appdata    /media/glacier/appdata
glacier/backup     /media/glacier/backup
glacier/documents  /media/glacier/documents
glacier/downloads  /media/glacier/downloads
glacier/gallery    /media/glacier/gallery
glacier/media      /media/glacier/media
```

### ZimaOS Integration via Symlinks

ZFS pools created via CLI are invisible to the ZimaOS storage UI. Datasets are exposed in the Files app via symlinks in `/DATA`:

```bash
ln -s /media/glacier/VM        /DATA/glacier-VM
ln -s /media/glacier/appdata   /DATA/glacier-AppData
ln -s /media/glacier/backup    /DATA/glacier-Backup
ln -s /media/glacier/documents /DATA/glacier-Documents
ln -s /media/glacier/downloads /DATA/glacier-Downloads
ln -s /media/glacier/gallery   /DATA/glacier-Gallery
ln -s /media/glacier/media     /DATA/glacier-Media
```

---

## Benchmark Methodology

### Tool
`fio 3.38` — natively available on ZimaOS Buildroot

### Test Parameters

| Test | Block size | Jobs | Queue depth | Size | Duration |
|---|---|---|---|---|---|
| Sequential write | 1M | 4 | 8 | 8GB | 60s |
| Sequential read | 1M | 4 | 8 | 8GB | 60s |
| Random 4K write | 4K | 4 | 32 | 4GB | 60s |
| Random 4K read | 4K | 4 | 32 | 4GB | 60s |

All tests used `--direct=1` (bypasses OS page cache) and `--ioengine=libaio`.

### Monitoring
Real-time metrics captured via Netdata running as a Docker container. Dashboard at `http://192.168.50.206:19999`.

---

## Results

### Glacier — ZFS RAIDZ1 (OCuLink)

| Test | Bandwidth | IOPS | Latency (avg) |
|---|---|---|---|
| Sequential write | **1,726 MB/s** | 1,646 | 19.4ms |
| Sequential read | **2,591 MB/s** | 2,470 | 12.9ms |
| Random 4K write | 56.5 MB/s | **13,795** | 9.3ms |
| Random 4K read | 60.5 MB/s | **14,781** | 8.7ms |

### Arctic-Storage — btrfs PCIe 5.0 (7th Bay, 800 MB/s cap)

| Test | Bandwidth | IOPS | Latency (avg) |
|---|---|---|---|
| Sequential write | **788 MB/s** | 751 | 42.6ms |
| Sequential read | **874 MB/s** | 833 | 38.4ms |
| Random 4K write | 357 MB/s | **87,099** | 1.5ms |
| Random 4K read | 842 MB/s | **205,588** | 0.6ms |

---

## Head-to-Head Comparison

| Test | Glacier ZFS RAIDZ1 | Arctic btrfs PCIe 5.0 | Winner |
|---|---|---|---|
| Sequential write | 1,726 MB/s | 788 MB/s | 🧊 Glacier (+119%) |
| Sequential read | 2,591 MB/s | 874 MB/s | 🧊 Glacier (+196%) |
| Random 4K write IOPS | 13,795 | 87,099 | 🌨️ Arctic (6.3×) |
| Random 4K read IOPS | 14,781 | 205,588 | 🌨️ Arctic (14×) |
| Random 4K write latency | 9.3ms | 1.5ms | 🌨️ Arctic (6× lower) |
| Random 4K read latency | 8.7ms | 0.6ms | 🌨️ Arctic (14× lower) |
| Usable capacity | 5.5TB | 1.8TB | 🧊 Glacier (3×) |
| Drive redundancy | 1 drive failure | None | 🧊 Glacier |
| Data integrity | ZFS checksums + self-healing | btrfs checksums | 🧊 Glacier |

---

## Analysis

### Why Glacier Wins Sequential Performance

With 4 drives in RAIDZ1, ZFS stripes reads across all drives simultaneously. The 2,591 MB/s sequential read result is **approximately 81% of the theoretical 3,200 MB/s OCuLink ceiling** — demonstrating strong, near-optimal read distribution across all 4 drives. The ~19% gap below theoretical maximum is normal ZFS overhead: metadata management, checksum verification, and stripe coordination.

Sequential write at 1,726 MB/s is excellent given RAIDZ1 parity overhead, which adds one parity block per stripe on every write operation.

The Arctic-Storage sequential results confirm the 7th Bay 800 MB/s bridge cap — both read (874 MB/s) and write (788 MB/s) are capped by the ASMedia bridge hardware, not the PCIe 5.0 drive itself. The Crucial P510 is capable of ~10,000 MB/s natively but the 7th Bay limits it to ~800 MB/s sequentially.

### Why Arctic-Storage Wins Random IOPS

The 205,588 random 4K read IOPS and 0.6ms average latency from Arctic-Storage is a remarkable result, revealing a fundamental architectural difference between ZFS RAIDZ1 and a single btrfs drive.

ZFS RAIDZ1 introduces copy-on-write overhead on every write, requires parity calculation, and has higher baseline latency (7–9ms) due to the OCuLink tunnel and RAIDZ stripe management. For small random I/O, this overhead dominates.

The Crucial P510 PCIe 5.0 drive, despite being capped at 800 MB/s sequentially, delivers its native NVMe random I/O performance completely unimpeded — resulting in 14× better random read IOPS than the RAIDZ1 pool.

### ZFS ARC Cache — Cold Cache vs Real-World Performance

The glacier random IOPS numbers represent **cold cache performance** — fio's `--direct=1` flag intentionally bypasses the ZFS ARC (Adaptive Replacement Cache). In real-world production use, ZFS ARC caches frequently accessed data in RAM, significantly improving random read performance over time.

| RAM | ZFS ARC Available | Real-World Impact |
|---|---|---|
| 16GB (current) | ~8–10GB | Hot Docker databases, small working sets stay in RAM |
| 32GB (planned) | ~20–24GB | Immich thumbnails + databases + Ollama model pages cached simultaneously |

Upgrading from 16GB to 32GB DDR5 doubles the ARC headroom — meaningfully improving glacier's day-to-day random read performance for Immich photo browsing, Docker app databases, and Ollama inference. The fio benchmark numbers won't change (they bypass ARC by design) but real workload performance will improve noticeably.

Monitor ARC effectiveness with:
```bash
awk '/^hits/{h=$3} /^misses/{m=$3} END{printf "ARC hit rate: %.1f%%\n", h/(h+m)*100}' \
  /proc/spl/kstat/zfs/arcstats
```
A healthy NAS ARC hit rate is typically **90–95%+** after a day or two of normal use.

---

## Recommended Workload Split

Based on these results, the optimal storage architecture for the ZimaCube 2 Pioneer build is:

| Workload | Storage | Reason |
|---|---|---|
| Immich photo library (87K photos) | Glacier | Large sequential reads, redundancy, 5.5TB capacity |
| Jellyfin/media library | Glacier | Sequential streaming, bulk capacity |
| VM disk images | Glacier | Large sequential, RAIDZ1 redundancy |
| Bulk backup target | Glacier | Capacity, ZFS data integrity |
| Docker AppData | Arctic-Storage | Low latency random I/O, native ZimaOS UI |
| Ollama model cache (Phase 4a) | Arctic-Storage | Low latency random reads for inference |
| Active databases (Postgres/Redis) | Arctic-Storage | High IOPS, sub-ms latency |
| ZimaOS system | Kingston nvme5n1 | Boot stability, OS independence |

---

## Notable Findings

### The Thunderbolt 4 → OCuLink Migration Story

Originally planned to connect the Aoostar TB4S-OC via Thunderbolt 4. After extensive troubleshooting, the TB4 connection failed due to:
- ZimaOS kernel parameter `thunderbolt.host_reset=false` preventing device enumeration
- `security=user` on TB domains requiring manual authorization that never completed
- `reading DROM failed: -107` (ENOTCONN) — ASMedia ASM2462PDX firmware incompatibility with ZimaCube 2's TB4 controller

Switching to OCuLink via a PCIe slot adapter resolved all issues immediately — drives detected on first boot, no configuration required.

**Community takeaway:** For Aoostar TB4S-OC + ZimaCube 2 — use OCuLink, not Thunderbolt 4.

### PCIe 5.0 Capped by 7th Bay Bridge

The Crucial P510 is capable of ~10,000 MB/s sequential read. The ZimaCube 2 Standard 7th Bay ASMedia bridge limits it to 800 MB/s sequentially. Despite this, the drive's random I/O performance is completely unaffected — delivering 205,588 IOPS and 0.6ms latency that represent genuine PCIe 5.0 NVMe performance.

### Planned Phase 1.5 — Onboard M.2 Re-benchmark

Moving the Crucial P510 from the 7th Bay to the additional onboard M.2 slot on the ZimaCube 2 motherboard will test whether native PCIe Gen5 speeds are achievable. Expected result: sequential read climbs from 874 MB/s to ~9,000+ MB/s. Results will be published as a follow-up post.

---

## Benchmark Scripts

Available in the `scripts/` folder:

- `benchmark-glacier.sh` — Glacier ZFS RAIDZ1 full benchmark suite
- `benchmark-arctic.sh` — Arctic-Storage btrfs full benchmark suite
- `benchmark-compare.sh` — Combined comparison with summary output

```bash
chmod +x scripts/*.sh
sudo -i
./scripts/benchmark-glacier.sh
./scripts/benchmark-arctic.sh
```

---

## Next Steps

- **Phase 1.5** — Move P510 to onboard M.2 slot → re-benchmark → publish
- **Phase 2** — Media server (Jellyfin) — on hold pending Seagate IronWolf drives
- **Phase 2.5** — Immich database restore from source instance — in progress
- **Phase 4a** — Ollama CPU-only AI inference baseline on i3-1215U (after RAM → 32GB)
- **Phase 4b** — RTX 4090 via TB4 eGPU or Minisforum DEG2 dock

---

## System Information at Time of Benchmark

```
Model:   ZimaCube 2 (Standard)
OS:      ZimaOS (Buildroot-based, immutable)
Kernel:  Linux 6.17.13-3-pve
ZFS:     OpenZFS 2.3.2
fio:     3.38
Date:    Saturday, May 23, 2026
```

---

*ZimaCube 2 Pioneer Program build documentation by ted-knight*  
*Benchmarks conducted May 23, 2026*  
*Feedback welcome — IceWhale Community Forum · Reddit r/ZimaCube · r/selfhosted · r/homelab*
