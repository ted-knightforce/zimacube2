# ZimaCube 2 — Phase 1: Storage Benchmark

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
`fio 3.38` — natively available on ZimaOS Buildroot. No installation required; confirmed with `fio --version` in the ZimaOS terminal.

### Terminal Access

ZimaOS does not expose SSH by default. The web-based terminal was accessed via:

1. Open ZimaOS **Settings**
2. Navigate to **General → Developer Mode**
3. Click **View** to open the Developer panel
4. Launch the **Web-based terminal**

All commands were run as root inside this session:

```bash
sudo -i
```

### Script Deployment via WinSCP

The benchmark scripts (maintained in this repo under [`docs/resources/scripts/`](../resources/scripts/)) were uploaded to the ZimaCube using **WinSCP** from the Windows host:

| | Path |
|---|---|
| **Local (repo)** | `docs/resources/scripts/` |
| **Remote (ZimaCube)** | `/DATA/Documents/nvme-benchmark/` |

WinSCP connection details:
- **Host:** `192.168.xxx.xxx`
- **Protocol:** SFTP
- **Port:** 22

Files uploaded:
- [`benchmark-glacier.sh`](../resources/scripts/benchmark-glacier.sh)
- [`benchmark-arctic.sh`](../resources/scripts/benchmark-arctic.sh)
- [`benchmark-compare.sh`](../resources/scripts/benchmark-compare.sh)

### Execution

Scripts were run individually from the `/DATA/Documents/nvme-benchmark/` folder in the ZimaOS web terminal:

```bash
sudo -i
cd /DATA/Documents/nvme-benchmark

chmod +x benchmark-glacier.sh benchmark-arctic.sh benchmark-compare.sh

# Run each benchmark individually
./benchmark-glacier.sh
./benchmark-arctic.sh
```

Each script runs 4 sequential fio tests (seq write → seq read → rand 4K write → rand 4K read), captures filesystem-specific stats, cleans up its temp file, and saves results automatically:

| Script | Results saved to |
|---|---|
| `benchmark-glacier.sh` | `/media/glacier/benchmark-results-glacier.txt` |
| `benchmark-arctic.sh` | `/media/Arctic-Storage/benchmark-results-arctic.txt` |
| `benchmark-compare.sh` | `/root/benchmark-comparison-summary.txt` |

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

Based on benchmark results and the full Phase 1–6 build plan, the optimal storage architecture across all three tiers is:

> **Storage tiers:**
> - 🧊 **Glacier** — ZFS RAIDZ1, 4× 2TB PCIe 4.0 NVMe via OCuLink (~5.5TB usable) — sequential throughput + redundancy
> - 🌨️ **Arctic-Storage** — Crucial P510 2TB PCIe 5.0 btrfs (7th Bay) — random IOPS, sub-ms latency
> - 💿 **sata-hdd** — 3× Seagate IronWolf 4TB ZFS RAIDZ1 (~8TB usable, arriving) — bulk cold storage, cost-per-TB
> - ⚙️ **nvme5n1** — Kingston 256GB OS drive — ZimaOS system only

### Phase 1 — Foundation (current)

| Workload | Pool | Reason |
|---|---|---|
| ZimaOS system + boot | `nvme5n1` | OS isolation; survives pool wipes |
| Docker AppData (all containers) | `Arctic-Storage` | 205K IOPS, 0.6ms latency — config DBs, container state |
| Immich photo library (87K photos) | `glacier` | Sequential reads, 5.5TB capacity, ZFS checksums, RAIDZ1 redundancy |
| Immich PostgreSQL + pgvecto.rs DB | `Arctic-Storage` | Random I/O critical for thumbnail queries, face search, CLIP search |
| Immich ML model cache | `Arctic-Storage` | Low latency random reads for face/scene detection inference |
| VM disk images | `glacier` | Sequential I/O, RAIDZ1 redundancy, ZFS snapshot rollback |
| Personal documents | `glacier` | Checksums + snapshots for irreplaceable data |
| ZimaOS system | `nvme5n1` | Boot stability, OS independence |

> **Note on Immich split:** The photo library (large sequential files) lives on `glacier` for capacity and redundancy. The PostgreSQL database lives on `Arctic-Storage` for IOPS. At 32GB RAM, ZFS ARC (~20–24GB) will partially warm Glacier's random I/O for hot DB pages, but the cold-cache penalty (8.7ms vs 0.6ms) is real for initial loads and fresh restarts.

### Phase 2 — Media Stack (SATA HDDs arriving)

| Workload | Pool | Reason |
|---|---|---|
| Jellyfin media library (movies, TV, music) | `sata-hdd` | Sequential streaming only; HDD speed (150–200 MB/s) comfortably covers 4K playback; saves NVMe for hot data |
| qBittorrent downloads (transient) | `sata-hdd` | Bulk writes, transient; **must be same pool as media** for hardlinks (zero-copy imports) |
| Bulk photo archive (Immich external library, read-only) | `sata-hdd` | Cold sequential reads; Immich indexes without moving files |
| Jellyfin AppData / metadata DB | `Arctic-Storage` | Random I/O for library scans, watch-state DB, playback resume |
| Jellyfin transcode cache (temp) | `Arctic-Storage` | High random I/O during Intel QuickSync transcode; ephemeral |
| Sonarr / Radarr / Prowlarr / Bazarr AppData | `Arctic-Storage` | SQLite config DBs — frequent small random writes on episode grabs |
| Jellyseerr AppData | `Arctic-Storage` | Request history DB |

### Phase 3 — Data Management + Backup

| Workload | Pool | Reason |
|---|---|---|
| Nextcloud data directory | `glacier` | User files; sequential reads/writes; RAIDZ1 redundancy important |
| Nextcloud database (MariaDB) | `Arctic-Storage` | Random I/O for file metadata, sharing, CalDAV/CardDAV queries |
| Time Machine backup target | `glacier` | Sequential writes, capacity, redundancy — backup integrity via ZFS checksums |
| Client machine backups (Kopia local, copy 2 of 3-2-1) | `glacier` | Redundancy + ZFS data integrity for backup destination |
| Kopia AppData (dedup index, config, cache) | `Arctic-Storage` | Random index lookups during backup runs |
| Syncthing AppData | `Arctic-Storage` | Config + index DB |
| ZFS snapshots | same pool as data | Copy-on-write — zero overhead until data diverges; auto-managed by sanoid |
| Offsite backup (Backblaze B2) | cloud | Kopia → B2 for irreplaceable datasets only (documents, gallery, vault, projects) |

### Phase 4a / 4b — Local AI (CPU then GPU)

| Workload | Pool | Reason |
|---|---|---|
| Ollama model files | `Arctic-Storage` | 0.6ms random reads — lower time-to-first-token vs 8.7ms on Glacier |
| Open WebUI AppData (chat history, config) | `Arctic-Storage` | Config DB, conversation history |
| GPU VRAM (Phase 4b, RTX 4090 24GB) | VRAM | Models loaded from Arctic-Storage into VRAM at session start; in-memory during inference |
| NVIDIA drivers / CUDA libs (Phase 4b) | `nvme5n1` | System-level install; stays on OS volume |

### Phase 5 — Semantic Search

| Workload | Pool | Reason |
|---|---|---|
| Khoj pgvector database | `Arctic-Storage` | Vector similarity search is extremely IOPS-sensitive; warm ARC won't overcome cold-cache gap at query time |
| Qdrant vector store (optional Path C) | `Arctic-Storage` | Same — embedding queries are random read-heavy by nature |
| nomic-embed-text model files | `Arctic-Storage` | Loaded like Ollama models; low latency reduces indexing time |
| Khoj / Qdrant AppData (config) | `Arctic-Storage` | Docker AppData |
| Semantic search source documents | `glacier` | Files live on Glacier; Khoj/Qdrant read them as input; files not duplicated |

### Phase 6 — Steam Machine

| Workload | Pool | Reason |
|---|---|---|
| Steam game library (installed games) | `sata-hdd` | Large sequential installs; HDD load times adequate for most titles via Proton |
| Steam Proton prefix / shader cache | `Arctic-Storage` | Random I/O during game runtime; sub-ms latency reduces shader stutter |
| Game save files | `glacier` | Small, irreplaceable — ZFS snapshot protection + RAIDZ1 redundancy |

### Quick-reference summary

| Pool | Workload pattern | What lives here |
|---|---|---|
| 🧊 `glacier` | Sequential I/O, redundancy, capacity | Photo library, documents, media library (pre-SATA), VM images, backups, Nextcloud files, game saves |
| 🌨️ `Arctic-Storage` | Random IOPS, sub-ms latency | All Docker AppData + DBs, Ollama models, vector DBs, transcode cache, Proton prefix |
| 💿 `sata-hdd` | Bulk cold storage, cost-per-TB | Movies, TV, music, qBittorrent downloads, bulk photo archive, Steam games |
| ⚙️ `nvme5n1` | OS only | ZimaOS boot, NVIDIA drivers (Phase 4b) |

---

## Notable Findings

### The Thunderbolt 4 → OCuLink Migration Story

Originally planned to connect the Aoostar TB4S-OC via Thunderbolt 4. After extensive troubleshooting, the TB4 connection failed due to:
- ZimaOS kernel parameter `thunderbolt.host_reset=false` preventing device enumeration
- `security=user` on TB domains requiring manual authorization that never completed
- `reading DROM failed: -107` (ENOTCONN) — ASMedia ASM2462PDX firmware incompatibility with ZimaCube 2's TB4 controller

Switching to OCuLink via a PCIe slot adapter resolved all issues immediately — drives detected on first boot, no configuration required.

**Troubleshooting takeaway:** For Aoostar TB4S-OC + ZimaCube 2 — use OCuLink, not Thunderbolt 4 (TBC).

### PCIe 5.0 Capped by 7th Bay Bridge

The Crucial P510 is capable of ~10,000 MB/s sequential read. The ZimaCube 2 Standard 7th Bay ASMedia bridge limits it to 800 MB/s sequentially. Despite this, the drive's random I/O performance is completely unaffected — delivering 205,588 IOPS and 0.6ms latency that represent genuine PCIe 5.0 NVMe performance.

### Planned Phase 1.5 — Onboard M.2 Re-benchmark

Moving the Crucial P510 from the 7th Bay to the additional onboard M.2 slot on the ZimaCube 2 motherboard will test whether native PCIe Gen5 speeds are achievable. Expected result: sequential read climbs from 874 MB/s to ~9,000+ MB/s. Results will be published as a follow-up post.

---

## Benchmark Scripts

Scripts are maintained in [`docs/resources/scripts/`](../resources/scripts/). Upload to the ZimaCube via WinSCP (see [Benchmark Methodology → Script Deployment](#script-deployment-via-winscp) above), then run from the ZimaOS web terminal.

| Script | Description |
|---|---|
| [`benchmark-glacier.sh`](../resources/scripts/benchmark-glacier.sh) | Runs all 4 fio tests against the Glacier ZFS RAIDZ1 pool (`/media/glacier`). Appends `zpool status`, compression ratios, and pool list to results. Saves output to `/media/glacier/benchmark-results-glacier.txt`. |
| [`benchmark-arctic.sh`](../resources/scripts/benchmark-arctic.sh) | Runs all 4 fio tests against Arctic-Storage btrfs (`/media/Arctic-Storage`). Appends `btrfs filesystem` info and NVMe SMART log. Saves output to `/media/Arctic-Storage/benchmark-results-arctic.txt`. |
| [`benchmark-compare.sh`](../resources/scripts/benchmark-compare.sh) | Runs all 8 tests back-to-back (Glacier then Arctic) and writes a side-by-side comparison summary to `/root/benchmark-comparison-summary.txt`. |

### Running the scripts

From the ZimaOS web terminal (as root, in the upload folder):

```bash
sudo -i
cd /DATA/Documents/nvme-benchmark

chmod +x benchmark-glacier.sh benchmark-arctic.sh benchmark-compare.sh

# Run individually (recommended — lets you monitor each in Netdata)
./benchmark-glacier.sh
./benchmark-arctic.sh

# Or run the full comparison in one pass
./benchmark-compare.sh
```

> **Note:** Scripts require `sudo -i` (full root environment), not just `sudo`. The `benchmark-arctic.sh` script also calls `nvme smart-log` — if `nvme-cli` is unavailable on your ZimaOS build, the SMART section will be skipped gracefully without affecting fio results.

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
