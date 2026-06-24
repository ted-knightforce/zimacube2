# 🧊 ZimaCube 2 Build: Modest AI-Powered NAS & Self-Hosting Cloud Platform

Personal documentation for building a tiered-storage, AI-capable self-hosting server on a **ZimaCube 2 Standard** — from unboxing to a fully configured NAS with local LLMs, media streaming, and own-device privacy.

**Author:** ted-knight  
**Program:** ZimaCube 2 Pioneer Program  
**Started:** May 21, 2026  
**Last updated:** June 25, 2026

📖 **[Full documentation site →](https://ted-knightforce.github.io/zimacube2)**

---

## 🚦 Build Status

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | Foundation — Storage, ZFS, Core Services | ✅ Complete |
| **Phase 1.5** | Storage Benchmarks — cold baseline + warm ZFS ARC | ✅ Complete |
| **Phase 1.8** | P510 Onboard M.2 Migration + Re-benchmark · 32GB dual-channel RAM | ✅ Complete |
| **Phase 2** | Media Stack — Jellyfin, *arr, IronWolf pool | 🟡 In Progress — `ironwolf` RAID5 created; media stack next |
| **Phase 2.5** | Immich Migration — 14,505 photos + 925 videos (134 GiB) from DIY ZimaOS to ZimaCube 2 | ✅ Complete |
| **Phase 3** | Data Management — Backup, Nextcloud | ⏳ Planned |
| **Phase 4a** | CPU-Only Local AI Baseline (Ollama) | ⏳ Planned |
| **Phase 4b** | GPU Integration — RTX 4090 + eGPU dock | ⏳ Planned |
| **Phase 5** | Semantic Search | ⏳ Planned |
| **Phase 6** | Steam Machine | ⏳ Future |

---

## 📦 Hardware Foundation

### Current Configuration (June 25, 2026)

> ℹ️ Device-node names (`nvmeXn1`) reshuffled after Phase 1.8 when the P510 moved to the onboard slot. They're assigned by the kernel at boot — identify drives by model/serial, not node.

| Component | Choice | Detail |
|---|---|---|
| **Base unit** | ZimaCube 2 Standard | i3-1215U · **32GB DDR5 dual-channel** (Corsair Vengeance 2× 16GB; upgraded from 8GB → 16GB → 32GB) · ZimaOS |
| **OS drive** | Kingston 256GB PCIe Gen4 NVMe | nvme4n1 — ZimaOS boot only |
| **Fast NVMe tier** | Crucial P510 2TB PCIe Gen5 | nvme5n1 — Arctic-Storage (btrfs) — **onboard M.2 (PCIe 3.0 x2) since Phase 1.8** — App Data, Docker |
| **NVMe RAID pool** | 4× 2TB PCIe Gen4 NVMe via Aoostar TB4S-OC | nvme0–3n1 — glacier (ZFS RAIDZ1) ~5.5TB |
| **SATA HDD pool** | 4× Seagate IronWolf 4TB (ST4000VN006, CMR) | **ironwolf — btrfs RAID5, 12TB usable** — bulk media cold tier (created June 24, 2026) |
| **Connection** | OCuLink via PCIe 4.0 x4 adapter (Slot 1, physical x16) | ⚠️ TB4 abandoned — see Phase 1 notes |
| **USB storage (temp)** | Transcend ESD310C 1TB + SanDisk 1TB | Temporary overflow — superseded by ironwolf; being retired |
| **Network** | 2× Intel i226 2.5GbE | 1 port connected to Ubiquiti Flex Mini 2.5G 5-Port Managed Switch · 2nd port unused (future use) |

### Key Hardware Decisions & Changes from Original Plan

> **⚠️ TB4 → OCuLink pivot:** The Aoostar TB4S-OC was originally planned to connect via Thunderbolt 4. After extensive troubleshooting, TB4 connection failed due to ZimaOS kernel configuration (`thunderbolt.host_reset=false`) and ASMedia ASM2462PDX firmware incompatibility. OCuLink via Slot 1 PCIe adapter resolved this immediately. See [Phase 1](https://ted-knightforce.github.io/zimacube2/phases/01-foundation/) for full details.

> **Slot 1 consequence:** With PCIe Slot 1 occupied by the OCuLink adapter, both TB4 ports are now free. The original plan to use a Minisforum DEG1 for Phase 4b GPU is no longer viable. Evaluating **Minisforum DEG2** (TB5 + OCuLink) or AooStar AG02/AG03 TB4/TB5 eGPU/OCuLink dock instead. The free TB4 ports also open up **IP over Thunderbolt** — direct Mac/PC connection that bypasses the 2.5GbE ceiling (~312 MB/s) and can expose the full sequential bandwidth of glacier (2,591 MB/s) and Arctic-Storage to a directly-connected client.

### Incoming Hardware

| Item | Purpose | ETA |
|---|---|---|
| RTX 4090 (used) | GPU inference + Phase 6 gaming | Phase 4b |
| eGPU dock (TBD) | Minisforum DEG2 or TB4 enclosure | Phase 4b |

*Recently installed: 32GB DDR5 dual-channel RAM (Phase 1.8) · 4× Seagate IronWolf 4TB → `ironwolf` btrfs RAID5 (June 24, 2026).*

---

## 💾 Storage Architecture

### Storage Tiers

```
ZimaCube 2 Standard — Storage Tiers
│
├── TIER 0 — OS
│   └── nvme4n1  Kingston 256GB PCIe Gen4     ZimaOS system drive (/DATA)
│
├── TIER 1 — Fast NVMe (active workloads)
│   └── nvme5n1  Crucial P510 2TB PCIe Gen5   Arctic-Storage (btrfs)
│                └── App Data, Docker images, User DB, active workloads
│                └── Onboard M.2 since Phase 1.8 (PCIe 3.0 x2, ~1,970 MB/s)
│                └── ~2× the old 7th Bay (800 MB/s) — but not full Gen5
│
├── TIER 2 — NVMe RAID (bulk NVMe)
│   └── nvme0–3n1  4× 2TB PCIe Gen4           glacier (ZFS RAIDZ1, ~5.5TB)
│                  └── Media, documents, VM, backup
│                  └── Via OCuLink (Aoostar TB4S-OC, Slot 1)
│
├── TIER 3 — USB Portable (being retired)
│   └── sda/sdb  Transcend + SanDisk 1TB      Overflow — superseded by ironwolf
│
└── TIER 4 — Cold Storage (active · created June 24, 2026)
    └── 4× Seagate IronWolf 4TB SATA           ironwolf (btrfs RAID5, 12TB usable)
                                               └── bays 1–4 · bulk media archive
```

### Pool & Path Quick Reference

| What | Pool | Path |
|---|---|---|
| Immich photo library | `Arctic-Storage` | `/DATA/Gallery/immich` |
| Media files | `glacier` | `/media/glacier/media` |
| Documents | `glacier` | `/media/glacier/documents` |
| VM disk images | `glacier` | `/media/glacier/VM` |
| Backup destination | `glacier` | `/media/glacier/backup` |
| App Data (Docker) | `Arctic-Storage` | `/media/Arctic-Storage/AppData` |
| Ollama AI models | `Arctic-Storage` | `/media/Arctic-Storage/AppData/ollama` |
| Movies | `ironwolf` | `/media/ironwolf/media/movies` |
| TV shows | `ironwolf` | `/media/ironwolf/media/tv` |
| Music | `ironwolf` | `/media/ironwolf/media/music` |

---

## 📊 Day 1–3 Benchmark Summary

Full benchmark details: [Phase 1.5 — Storage Benchmarks](https://ted-knightforce.github.io/zimacube2/phases/01.5-benchmarks/)

| Test | Glacier ZFS RAIDZ1 | Arctic btrfs PCIe 5.0 | Winner |
|---|---|---|---|
| Sequential write | 1,726 MB/s | 788 MB/s | 🧊 Glacier +119% |
| Sequential read | 2,591 MB/s | 874 MB/s | 🧊 Glacier +196% |
| Random 4K write IOPS | 13,795 | 87,099 | 🌨️ Arctic 6.3× |
| Random 4K read IOPS | 14,781 | 205,588 | 🌨️ Arctic 14× |
| Random 4K latency | 8.7ms | 0.6ms | 🌨️ Arctic 14× lower |

---

## 📈 Post-Upgrade Benchmark Summary (June 24–25, 2026)

After **Phase 1.8** — the Crucial P510 moved from the 7th Bay to the **onboard M.2 slot**, and RAM went from **16GB single-channel → 32GB dual-channel**. Two re-benchmarks captured what changed. Full analysis + the PCIe link investigation: [Phase 1.5 — Phase 1.8 results](https://ted-knightforce.github.io/zimacube2/phases/01.5-benchmarks/#phase-18-p510-onboard-migration-june-25-2026) · [interactive comparison chart](https://ted-knightforce.github.io/zimacube2/benchmarks/results-visual.html).

**① Arctic-Storage (P510) — 7th Bay → Onboard M.2**

| Test | 7th Bay (before) | Onboard M.2 (after) | Change |
|---|---|---|---|
| Sequential write | 788 MB/s | 1,231 MB/s | 🟢 +56% |
| Sequential read | 874 MB/s | 1,677 MB/s | 🟢 +92% |
| Random 4K write IOPS | 87,099 | 59,682 | 🔴 −31% * |
| Random 4K read IOPS | 205,588 | 403,078 | 🟢 +96% |
| Random 4K read latency | 0.6 ms | 0.32 ms | 🟢 −47% |

> The onboard slot is **PCIe 3.0 x2** (~1,970 MB/s) — roughly 2× the old 7th Bay (800 MB/s cap), but not the P510's full Gen5. No slot in the Standard chassis exposes it.
> \* The random-write dip isn't the slot — the drive is now ~43% full vs near-empty originally, which shrinks the SLC cache.

**② Glacier (ZFS RAIDZ1) warm ARC — 16GB single-channel → 32GB dual-channel**

| Test | 16GB single-channel | 32GB dual-channel | Change |
|---|---|---|---|
| Warm ARC random 4K read | 83,929 IOPS @ 1.48 ms | 126,816 IOPS @ 1.01 ms | 🟢 +51% IOPS · −32% latency |
| Warm-up sequential read | 4,328 MB/s | 4,711 MB/s | 🟢 +9% |

> Disk-bound numbers (writes, cold reads) stayed flat — only the RAM-served ARC path moved. The +51% is pure **dual-channel memory bandwidth**, confirmed across two runs. ZFS ARC scales with *dual-channel* RAM, not just capacity.

---

## 📂 Documentation

Browse the source files directly below, or visit the full docs site for navigation, search, and dark mode:

📖 **[Full documentation site → ted-knightforce.github.io/zimacube2](https://ted-knightforce.github.io/zimacube2)**

| Phase | Doc |
|---|---|
| **Phase 1** | [ZimaCube 2 Build — Phase 1: Foundation & Storage](docs/phases/01-foundation.md) |
| **Phase 1.5** | [Phase 1.5 — Storage Benchmarks](docs/phases/01.5-benchmarks.md) |
| **Phase 2** | [Phase 2 — Media Stack: Jellyfin, *arr, IronWolf Pool](docs/phases/02-media.md) |
| **Phase 2.5** | [Phase 2.5 — Immich: Migration & iCloud Photos Consolidation](docs/phases/02.5-immich.md) |
| **Phase 3** | [Phase 3 — Data Management: Backup, Nextcloud & 3-2-1 Strategy](docs/phases/03-data.md) |
| **Phase 4a** | [Phase 4a — Running Local AI on a NAS Before the GPU Arrives](docs/phases/04a-cpu-ai.md) |
| **Phase 4b** | [Phase 4b — Adding an RTX 4090: What 24GB of VRAM Changes](docs/phases/04b-gpu-ai.md) |
| **Benchmarks** | [Phase 1.5: Storage Benchmarks](docs/phases/01.5-benchmarks.md) · [Results Visualisation ↗](https://ted-knightforce.github.io/zimacube2/benchmarks/results-visual.html) |

---

## 🗓️ Content Calendar

| Week | Phase | Post Title | Reddit |
|---|---|---|---|
| 2 | 1 | "ZimaCube 2 Pioneer — Day 1: ZFS RAIDZ1 via OCuLink, Tiered Storage & a TB4 Rabbit Hole" | r/ZimaCube + r/homelab |
| 3 | 1.5 | "ZFS RAIDZ1 vs PCIe 5.0 btrfs on a $799 NAS — Cold Benchmarks & the Warm ARC Reality" | r/ZimaCube + r/homelab |
| 4 | 2.5 | "Setting Up Immich on ZimaCube 2 — Migrating 14,505 Photos from DIY ZimaOS (Zero Data Loss)" | r/selfhosted |
| 5 | 1.8 | "PCIe 5.0 NVMe in the 7th Bay vs Onboard M.2 Slot — Does It Matter?" | r/ZimaCube |
| 6 | 2 | "*arr Stack on ZimaOS — App Store First, Compose Where Needed" | r/selfhosted |
| 8 | 4a | "Local AI on a $799 NAS Before the GPU — Honest CPU-Only Benchmarks" | r/LocalLLaMA |
| 11 | 4b | "Adding an RTX 4090 to ZimaCube 2 — What 24GB VRAM Actually Buys You" | r/LocalLLaMA + r/eGPU |
| 13 | 5 | "Semantic Search on ZimaCube 2: Current offerings vs DIY" | r/selfhosted |

---

*ZimaCube 2 Pioneer Program · ted-knight · Feedback welcome on IceWhale Community Forum and Reddit r/ZimaCube*
