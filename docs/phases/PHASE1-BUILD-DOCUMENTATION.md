# ZimaCube 2 Pioneer Build — Phase 1: Hardware Setup & Storage Benchmark

**Author:** ted-knight  
**Date:** May 23, 2026  
**Program:** ZimaCube 2 Pioneer Program  


---

## Table of Contents

1. [Build Journey](#build-journey)
2. [Final Hardware Configuration](#final-hardware-configuration)
3. [Storage Architecture](#storage-architecture)
4. [Thunderbolt 4 Issue & OCuLink Resolution](#thunderbolt-4-issue--oculink-resolution)
5. [ZFS Pool Setup](#zfs-pool-setup)
6. [ZimaOS Integration](#zimaos-integration)
7. [Benchmark Methodology](#benchmark-methodology)
8. [Benchmark Results](#benchmark-results)
9. [Analysis](#analysis)
10. [Recommended Workload Split](#recommended-workload-split)
11. [What's Coming Next](#whats-coming-next)

---

## Build Journey

This build started as a **standard ZimaCube 2 with 8GB RAM** — the base configuration fresh out of the box. Over a single weekend, it was upgraded significantly into a proper homelab NAS/AI machine.

The choice of ZimaOS was deliberate — after years with Synology, the simplicity of ZimaOS combined with its Docker-focused app deployment model made it the natural replacement. Everything runs as a container, the UI stays clean, and the OS stays out of the way.

### Upgrades Made This Weekend

**1. RAM Upgrade**  
Replaced the stock 8GB DDR5 with a **Crucial 16GB DDR5 5600MHz CL46 SODIMM**. Planning to upgrade further with **2× Corsair Vengeance 16GB DDR5 4800MHz CL40 SODIMM** for a total of **32GB DDR5** — the maximum supported by the ZimaCube 2 Standard.

> Note: The ZimaCube 2 Standard supports up to 32GB DDR5 (2× 16GB SODIMM). It does not support 64GB.

**2. Internal NVMe — Crucial P510 2TB PCIe 5.0 (7th Bay)**  
Installed a **Crucial P510 2TB Gen5 NVMe M.2 2280** into the ZimaCube 2's internal 7th Bay NVMe enclosure. Formatted as native ZimaOS btrfs, named **Arctic-Storage** (`nvme0n1`). ZimaOS App Data and User Database migrated here from the Kingston OS drive (`nvme5n1`) via the built-in migration tool.

> ⚠️ **Note:** The 7th Bay on the ZimaCube 2 Standard is capped at 800 MB/s total by the ASMedia bridge — the PCIe 5.0 speed of the Crucial P510 drive is completely wasted here sequentially. A cheaper PCIe 3.0 or 4.0 drive delivers identical sequential performance in this slot. However, random IOPS are unaffected by the bridge cap, making the 205K IOPS and 0.6ms latency of the P510 genuinely useful for Docker app workloads.

> 🔬 **Planned experiment — Phase 1.5:** Move the Crucial P510 from the 7th Bay to an additional onboard M.2 slot on the ZimaCube 2 motherboard to see whether the drive can achieve native PCIe 5.0 speeds. Re-benchmark results will be published when complete.

**3. PCIe OCuLink Adapter**  
Installed a **PCIe x4 to SFF-8612 adapter** into Slot 1 of ZimaCube 2. Slot 1 provides PCIe 4.0 x4 bandwidth (~8 GB/s) as the host-side connection for the OCuLink DAS.

> 💡 **Side effect:** With Slot 1 occupied by the OCuLink adapter, both Thunderbolt 4 ports on the ZimaCube 2 are now free. These could be used for a **Thunderbolt 4 eGPU** connection as an alternative to the originally planned ZimaSpace OCuLink dock for Phase 4b GPU inference.

**4. Aoostar TB4S-OC NVMe Enclosure (OCuLink)**  
Connected the **Aoostar TB4S-OC** (USB4/Thunderbolt 4 + OCuLink NVMe DAS) via OCuLink after Thunderbolt 4 failed (see [Thunderbolt 4 Issue](#thunderbolt-4-issue--oculink-resolution)). The enclosure holds **4× 2TB PCIe Gen4 NVMe M.2 SSDs** (`nvme1n1`–`nvme4n1`), formatted as **ZFS RAIDZ1** named **glacier**.

**5. USB Storage (temporary)**  
Two portable SSDs connected via USB ports while waiting for SATA HDDs to arrive:
- **Transcend ESD310C 1TB** — USB 10Gbps, dual Type-C/Type-A (`sda`)
- **SanDisk Portable SSD SDSSDE30 1TB** — USB 3.2 Gen 2, up to 800 MB/s (`sdb`)

**Coming soon:** 3× Seagate IronWolf 4TB 3.5" SATA NAS drives (5,400 RPM, CMR, 256MB cache) for cold storage RAID in the 6 SATA bays — bulk media files, movies, TV shows, photos archive.

---

## Final Hardware Configuration

### ZimaCube 2 Standard — Complete Spec

| Component | Specification |
|---|---|
| Model | ZimaCube 2 (Standard) |
| CPU | Intel Core i3-1215U (12th Gen Alder Lake, 6-core) |
| RAM | 16GB DDR5 — Crucial 5600MHz CL46 SODIMM |
| RAM (planned) | 2× 16GB Corsair Vengeance DDR5 4800MHz CL40 SODIMM = **32GB DDR5 (max)** |
| OS | ZimaOS (Buildroot-based, immutable, RAUC A/B OTA) |
| Network | 2× Intel i226 2.5GbE |
| Thunderbolt | 2× Thunderbolt 4 ports (both free — potential eGPU use) |
| PCIe Slot 1 | PCIe 4.0 x4 → OCuLink SFF-8612 adapter |
| PCIe Slot 2 | PCIe 3.0 x2 → available |
| 7th Bay | 4× M.2 NVMe slots (800 MB/s total on Standard) |
| Onboard M.2 | Additional slot available → planned P510 migration |
| SATA Bays | 6× 3.5"/2.5" SATA bays (empty — drives arriving soon) |

> **Standard vs Pro:** The ZimaCube 2 Standard uses the same 7th Bay physical layout as the Pro, but the ASMedia bridge limits total 7th Bay bandwidth to 800 MB/s (vs 3,200 MB/s on Pro/Creator). Standard has 2.5GbE-only network (no 10GbE) and an i3-1215U vs the Pro's i5-1235U.

### NVMe Drive Inventory

| Device | Model | Capacity | Interface | Location | Role |
|---|---|---|---|---|---|
| `nvme5n1` | Kingston OM8PGP4 256GB | 256GB | PCIe Gen4 | Onboard M.2 | ZimaOS boot drive |
| `nvme0n1` | Crucial P510 (CT2000P510SSD8) | 2TB | PCIe Gen5 | 7th Bay Slot 1 | Arctic-Storage (btrfs) — may move to onboard slot |
| `nvme1n1` | ORICO 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |
| `nvme2n1` | ORICO 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |
| `nvme3n1` | XPG GAMMIX S70 BLADE 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |
| `nvme4n1` | XPG GAMMIX S70 BLADE 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |

### Full NVMe List (from `nvme list`)

```
NAME    TYPE MODEL                   SERIAL                    REV      TRAN  RQ-SIZE  MQ
nvme4n1 disk XPG GAMMIX S70 BLADE    2O392L2KE7HJ         3.2.J.JE nvme      1023   8
nvme3n1 disk XPG GAMMIX S70 BLADE    2O042LCN42WX         3.2.J.JE nvme      1023   8
nvme0n1 disk CT2000P510SSD8          2537E9CA8E7A         K1CR5102 nvme      1023   8
nvme2n1 disk ORICO                   XFEFCXMAO7QKT67N27AO GT8ed336 nvme      1023   8
nvme1n1 disk ORICO                   SJVB1S14B2FTKWX35VZ3 GT8ed336 nvme      1023   8
nvme5n1 disk KINGSTON OM8PGP4256Q-A0 50026B7384587960     ELFK0S.6 nvme      1023   8
```

### USB Storage (Temporary)

| Device | Model | Capacity | Interface | Role |
|---|---|---|---|---|
| `sda` | Transcend ESD310C | 1TB | USB 10Gbps (Type-C + Type-A) | Temporary media/backup |
| `sdb` | SanDisk SDSSDE30 Portable SSD | 1TB | USB 3.2 Gen 2, up to 800 MB/s | Temporary overflow storage |

### Incoming Hardware

| Item | Specification | Purpose |
|---|---|---|
| Seagate IronWolf × 3 | 4TB, 3.5", SATA 6Gb/s, 5,400 RPM, CMR, 256MB cache | Cold storage RAID — bulk media |
| Corsair Vengeance × 2 | 16GB DDR5 4800MHz CL40 SODIMM | RAM upgrade to 32GB DDR5 (max) |

---

## Storage Architecture

### Current Storage Tiers

```
ZimaCube 2 Standard — Storage Tiers
│
├── TIER 0 — OS (Boot)
│   └── nvme5n1  Kingston 256GB PCIe Gen4     ZimaOS system drive
│
├── TIER 1 — Fast NVMe (Active workloads)
│   └── nvme0n1  Crucial P510 2TB PCIe Gen5   Arctic-Storage (btrfs)
│                └── App Data, Docker images, User database
│                └── Currently: 7th Bay (800 MB/s sequential cap)
│                └── Planned:   Onboard M.2 slot (native PCIe Gen5 speed)
│
├── TIER 2 — NVMe RAID (Bulk NVMe storage)
│   └── nvme1n1  ORICO 2TB PCIe Gen4          ┐
│   └── nvme2n1  ORICO 2TB PCIe Gen4          ├── glacier (ZFS RAIDZ1)
│   └── nvme3n1  XPG GAMMIX S70 BLADE 2TB     ├── ~5.5TB usable
│   └── nvme4n1  XPG GAMMIX S70 BLADE 2TB     ┘
│                └── Immich gallery, media, backup, VM, documents
│                └── Via OCuLink (Aoostar TB4S-OC, Slot 1)
│
├── TIER 3 — USB Portable (Temporary)
│   └── sda      Transcend ESD310C 1TB USB    Temporary
│   └── sdb      SanDisk Portable SSD 1TB     Temporary
│
└── TIER 4 — Cold Storage (Arriving soon)
    └── 3× Seagate IronWolf 4TB 3.5" SATA     Bulk media ZFS RAIDZ1
```

### ZFS Pool Status

```
pool: glacier
state: ONLINE
config:
    NAME         STATE     READ WRITE CKSUM
    glacier      ONLINE       0     0     0
      raidz1-0   ONLINE       0     0     0
        nvme1n1  ONLINE       0     0     0
        nvme2n1  ONLINE       0     0     0
        nvme3n1  ONLINE       0     0     0
        nvme4n1  ONLINE       0     0     0
errors: No known data errors

NAME     SIZE   ALLOC   FREE  FRAG  CAP  DEDUP  HEALTH
glacier  7.44T   346G  7.10T    0%    4%  1.00x  ONLINE
```

---

## Thunderbolt 4 Issue & OCuLink Resolution

### What Happened

The Aoostar TB4S-OC was originally intended to connect via Thunderbolt 4. After extensive troubleshooting across multiple sessions, the connection failed consistently with the following kernel errors:

```
thunderbolt: tb_path_activate+0x100/0x350 [thunderbolt]
thunderbolt 0000:00:0d.2: 0:8 <-> 1:3 (PCI): activation failed
thunderbolt 1-1: reading DROM failed: -107
thunderbolt 1-1: failed to initialize port 1
[endless retimer connect/disconnect loop in dmesg]
```

### Root Causes

| Issue | Detail |
|---|---|
| `thunderbolt.host_reset=false` | ZimaOS kernel boot parameter — TB controller won't reset when new device plugged in |
| `security=user` on both TB domains | All TB devices require manual authorization before PCIe tunneling; device never enumerated to authorize |
| `DROM failed: -107 (ENOTCONN)` | ASMedia ASM2462PDX inside Aoostar can't complete DROM handshake with ZimaCube 2 TB controller |
| One TB port dead at boot | `0000:00:0d.3: 0:1: failed to reach state TB_PORT_UP. Ignoring port` |

### Resolution

Installed a **PCIe x4 → SFF-8612 OCuLink adapter** in Slot 1. All 4 drives detected on first boot. Zero configuration needed.

### Downstream Impact on Phase 4b eGPU

With PCIe Slot 1 occupied by the OCuLink adapter:
- ~~Minisforum DEG1~~ (OCuLink-only) → ruled out (Slot 1 occupied)
- Both TB4 ports now free → **Minisforum DEG2** (TB5 + OCuLink) or a AooStar AG02/AG03 TB4/TB5 + OCulink eGPU dock are the viable paths

### Troubleshooting Takeaway

If connecting an Aoostar TB4S-OC (or any ASM2462PDX-based NVMe enclosure) to a ZimaCube 2 — **use OCuLink, not Thunderbolt 4**. Direct PCIe via OCuLink means no tunneling protocol, no authorization requirements, no firmware handshake. It also delivers lower latency than TB4 tunneling.

---

## ZFS Pool Setup

### Why ZFS RAIDZ1

| Factor | Decision |
|---|---|
| Data integrity | ZFS checksums detect and self-heal silent corruption — critical for photo and document storage |
| Redundancy | RAIDZ1 survives 1 drive failure across 4 drives |
| Snapshots | Copy-on-write snapshots are instant — essential before Phase 4 experiments |
| Compression | lz4 is near-zero CPU cost on i3-1215U with real savings on documents and logs |
| btrfs for Arctic-Storage | Single drive — ZimaOS native UI recognition matters more than ZFS on a single drive |

### Pool Creation

```bash
sudo -i

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

zpool set autotrim=on glacier
```

### Datasets

```bash
zfs create glacier/VM
zfs create glacier/appdata
zfs create glacier/backup
zfs create glacier/documents
zfs create glacier/downloads
zfs create glacier/gallery
zfs create glacier/media
```

---

## ZimaOS Integration

### Why CLI-Created ZFS Pools Don't Appear in ZimaOS UI

ZimaOS uses an internal SQLite database (`local-storage.db`) to track storage. Only pools created through the ZimaOS RAID wizard are registered. CLI-created ZFS pools are invisible to the storage dashboard and Apps migration tool. This is a known limitation — open feature request on ZimaOS GitHub.

### Solution — Symlinks in /DATA

```bash
ln -s /media/glacier/VM        /DATA/glacier-VM
ln -s /media/glacier/appdata   /DATA/glacier-AppData
ln -s /media/glacier/backup    /DATA/glacier-Backup
ln -s /media/glacier/documents /DATA/glacier-Documents
ln -s /media/glacier/downloads /DATA/glacier-Downloads
ln -s /media/glacier/gallery   /DATA/glacier-Gallery
ln -s /media/glacier/media     /DATA/glacier-Media
```

### AppData Migration to Arctic-Storage

ZimaOS's built-in **Settings → Storage → Apps** migration tool moved App Data from ZimaOS-HD to Arctic-Storage natively. ZimaOS created symlinks automatically — all apps continued working without reconfiguration:

```
AppData   → /media/Arctic-Storage/AppData
Documents → /media/Arctic-Storage/Documents
Downloads → /media/Arctic-Storage/Downloads
Gallery   → /media/Arctic-Storage/Gallery
Backup    → /media/Arctic-Storage/Backup
Media     → /media/Arctic-Storage/Media
```

---

## Benchmark Methodology

### Tool
`fio 3.38` — natively available on ZimaOS Buildroot

> **Note:** ZimaOS is Buildroot-based with no `apt`, `yum`, or package manager. `fio`, `zpool`, `zfs`, `nvme`, and `iostat` are available natively. All other software runs as Docker containers.

### Test Parameters

| Test | Block size | Jobs | Queue depth | Size | Duration |
|---|---|---|---|---|---|
| Sequential write | 1M | 4 | 8 | 8GB | 60s |
| Sequential read | 1M | 4 | 8 | 8GB | 60s |
| Random 4K write | 4K | 4 | 32 | 4GB | 60s |
| Random 4K read | 4K | 4 | 32 | 4GB | 60s |

All tests: `--direct=1` (bypasses OS page cache) · `--ioengine=libaio`

### Monitoring

Real-time metrics captured via **Netdata** running as a Docker container with host filesystem mounted read-only. Dashboard at `http://192.168.50.206:19999`.

---

## Benchmark Results

### Glacier — ZFS RAIDZ1 (OCuLink) — May 23, 2026

| Test | Bandwidth | IOPS | Avg latency |
|---|---|---|---|
| Sequential write | **1,726 MB/s** | 1,646 | 19.4ms |
| Sequential read | **2,591 MB/s** | 2,470 | 12.9ms |
| Random 4K write | 56.5 MB/s | **13,795** | 9.3ms |
| Random 4K read | 60.5 MB/s | **14,781** | 8.7ms |

### Arctic-Storage — btrfs PCIe 5.0 (7th Bay, 800 MB/s cap) — May 23, 2026

| Test | Bandwidth | IOPS | Avg latency |
|---|---|---|---|
| Sequential write | **788 MB/s** | 751 | 42.6ms |
| Sequential read | **874 MB/s** | 833 | 38.4ms |
| Random 4K write | 357 MB/s | **87,099** | 1.5ms |
| Random 4K read | 842 MB/s | **205,588** | 0.6ms |

### Head-to-Head Comparison

| Test | Glacier ZFS RAIDZ1 | Arctic btrfs PCIe 5.0 | Winner |
|---|---|---|---|
| Sequential write | 1,726 MB/s | 788 MB/s | 🧊 Glacier +119% |
| Sequential read | 2,591 MB/s | 874 MB/s | 🧊 Glacier +196% |
| Random 4K write IOPS | 13,795 | 87,099 | 🌨️ Arctic 6.3× |
| Random 4K read IOPS | 14,781 | 205,588 | 🌨️ Arctic 14× |
| Random 4K write latency | 9.3ms | 1.5ms | 🌨️ Arctic 6× lower |
| Random 4K read latency | 8.7ms | 0.6ms | 🌨️ Arctic 14× lower |
| Usable capacity | 5.5TB | 1.8TB | 🧊 Glacier 3× |
| Drive redundancy | 1 drive failure | None | 🧊 Glacier |
| Data integrity | ZFS checksums + self-healing | btrfs checksums | 🧊 Glacier |

---

## Analysis

### Sequential Performance — Glacier Dominates

With 4 drives in RAIDZ1, ZFS stripes reads across all drives simultaneously. The 2,591 MB/s sequential read result is **approximately 81% of the theoretical 3,200 MB/s OCuLink ceiling** — demonstrating strong, near-optimal read distribution across all 4 drives. The remaining ~19% gap is expected ZFS overhead: metadata management, checksum verification, and stripe coordination.

Sequential write at 1,726 MB/s is strong given RAIDZ1 parity overhead, which adds one parity block per stripe across every write.

Arctic-Storage sequential results confirm the 800 MB/s Standard 7th Bay bridge cap — both read (874 MB/s) and write (788 MB/s) are bottlenecked by the ASMedia bridge hardware, not the PCIe 5.0 drive itself.

### Random IOPS — Arctic Dominates

Arctic-Storage delivers **205,588 IOPS** random 4K read at **0.6ms average latency** — completely unimpeded by the 7th Bay sequential cap. This is genuine PCIe 5.0 NVMe random I/O performance.

Glacier's 14,781 IOPS reflects ZFS RAIDZ1 copy-on-write overhead, parity calculation latency, and OCuLink tunnel baseline latency. These are **cold-cache numbers** — in practice, ZFS ARC (Adaptive Replacement Cache) will cache frequently accessed data in RAM, significantly improving random read performance over time.

### ZFS ARC — Impact of RAM Upgrade

The glacier cold-cache IOPS numbers are what fio measures with `--direct=1`, bypassing the OS cache. In real workloads, ZFS ARC uses available RAM as a transparent read cache:

| RAM | ARC Available | What This Means |
|---|---|---|
| 16GB (current) | ~8–10GB | Hot Docker databases, small working sets |
| 32GB (planned) | ~20–24GB | Immich thumbnails + databases + Ollama model pages simultaneously |

Upgrading to 32GB DDR5 doubles the ARC headroom — meaningfully improving glacier's real-world random read performance for Immich photo browsing, Docker app databases, and eventual Ollama inference without changing any hardware except RAM. The benchmark numbers won't change (fio bypasses ARC intentionally) but day-to-day workload performance will.

### The 14× IOPS Gap — Architectural, Not a Flaw

ZFS RAIDZ1 trades random I/O efficiency for sequential throughput, redundancy, and data integrity. The correct response is tiered workload routing — not trying to close the gap.

---

## Recommended Workload Split

| Workload | Storage | Reason |
|---|---|---|
| Immich photo library (87K photos) | Glacier | Large sequential reads, redundancy, 5.5TB capacity |
| Jellyfin/Emby media library | Glacier | Sequential streaming, bulk capacity |
| VM disk images | Glacier | Large sequential, RAIDZ1 redundancy |
| Bulk backup target | Glacier | Capacity, ZFS data integrity |
| Docker AppData | Arctic-Storage | Low latency random I/O, native ZimaOS UI |
| Ollama model cache (Phase 4a) | Arctic-Storage | Low latency random reads for inference |
| Active databases (Postgres/Redis) | Arctic-Storage | High IOPS, sub-ms latency |
| Cold media archive | Seagate IronWolf RAID (arriving) | Bulk capacity, cost-per-TB |
| ZimaOS system | Kingston nvme5n1 | Boot stability, OS independence |

---

## What's Coming Next

### Planned Hardware Upgrades

| Upgrade | Detail | Impact |
|---|---|---|
| RAM → 32GB DDR5 | 2× Corsair Vengeance 16GB DDR5 4800MHz CL40 (max for Standard) | Doubles ZFS ARC headroom; better VM and AI performance |
| P510 → onboard M.2 | Move Crucial P510 from 7th Bay to onboard slot | Unlock native PCIe Gen5 speeds — re-benchmark planned |
| 3× Seagate IronWolf 4TB | SATA bays — ZFS RAIDZ1 cold storage | Bulk media archive tier |
| eGPU dock (TBD) | Minisforum DEG2 (TB5+OCuLink) or TB4 eGPU enclosure | Phase 4b GPU inference — both TB4 ports now free |

### Planned Experiments

- **Phase 1.5:** Move Crucial P510 to onboard M.2 slot → re-run `benchmark-arctic.sh` → publish comparison. Expected: sequential speeds climb from ~800 MB/s to 9,000+ MB/s; random IOPS similar.

### Software Phases

| Phase | Description |
|---|---|
| **Phase 2** | Jellyfin media server — Intel QuickSync transcoding, glacier/media library (on hold — SATA drives arriving) |
| **Phase 2.5** | Immich setup and database restore — glacier/gallery, 87K photos (in progress) |
| **Phase 3** | Personal cloud, Nextcloud, 3-2-1 backup strategy |
| **Phase 4a** | Ollama CPU-only AI baseline — i3-1215U inference benchmarks |
| **Phase 4b** | GPU-accelerated inference — RTX 4090 via TB4 eGPU or Minisforum DEG2 |
| **Phase 5** | Local AI semantic search across glacier storage |
| **Phase 6** | Steam Machine — bare metal Linux gaming |

---

## Benchmark Scripts

Available in `scripts/` folder:

| Script | Purpose |
|---|---|
| `benchmark-glacier.sh` | Full fio benchmark suite for glacier ZFS RAIDZ1 |
| `benchmark-arctic.sh` | Full fio benchmark suite for Arctic-Storage btrfs |
| `benchmark-compare.sh` | Combined benchmark with side-by-side summary output |

```bash
scp scripts/*.sh root@<zimaos-ip>:/root/
chmod +x /root/*.sh
sudo -i
./benchmark-glacier.sh
```

> **Known issue:** `hostname -I` is unsupported on ZimaOS Buildroot. The scripts use `ip addr` instead. If running an older version of the scripts, replace `hostname -I` with `ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1`.

---

## System Information

```
Model:     ZimaCube 2 (Standard)
OS:        ZimaOS (Buildroot-based, immutable)
Kernel:    Linux 6.17.13-3-pve
ZFS:       OpenZFS 2.3.2
fio:       3.38
Netdata:   Latest (Docker)
Date:      Saturday, May 23, 2026
```

---

## Resources

- [ZimaOS Documentation](https://www.zimaspace.com/docs/zimaos/zfs-setup)
- [IceWhale Community Forum](https://community.zimaspace.com)
- [ZimaOS GitHub — RAIDZ Feature Request](https://github.com/IceWhaleTech/ZimaOS/issues)
- [OpenZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [Aoostar TB4S-OC](https://www.aoostar.com)

---

*ZimaCube 2 Pioneer Program build documentation by ted-knight*  
*Build weekend: May 21–23, 2026*  
*Feedback welcome — IceWhale Community Forum · Reddit r/ZimaCube · r/selfhosted · r/homelab*
