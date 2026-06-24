# ZimaCube 2 Build

Personal documentation for building a tiered-storage, AI-capable self-hosting server on a **ZimaCube 2 Standard** — from unboxing to a fully configured NAS with local LLMs, media streaming, and own-device privacy.

**Program:** ZimaCube 2 Pioneer Program · **Started:** May 21, 2026

---

## Build Status

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | Foundation — Storage, ZFS, Core Services | 🟡 In Progress |
| **Phase 1.5** | Storage Benchmarks — cold baseline + warm ZFS ARC | ✅ Complete |
| **Phase 1.8** | P510 Onboard M.2 Migration + Re-benchmark · 32GB dual-channel RAM | ✅ Complete |
| **Phase 2** | Media Stack — Jellyfin, *arr, IronWolf pool | 🟡 In Progress — `ironwolf` RAID5 created |
| **Phase 2.5** | Immich Migration — 14,505 photos + 925 videos (134 GiB) | ✅ Complete |
| **Phase 3** | Data Management — Backup, Nextcloud | ⏳ Planned |
| **Phase 4a** | CPU-Only Local AI Baseline (Ollama) | ⏳ Planned |
| **Phase 4b** | GPU Integration — RTX 4090 + eGPU dock | ⏳ Planned |
| **Phase 5** | Semantic Search | ⏳ Planned |
| **Phase 6** | Steam Machine | ⏳ Future |

---

## Storage Architecture

| Pool | Hardware | Filesystem | Capacity |
|---|---|---|---|
| `glacier` | 4× 2TB PCIe Gen4 NVMe via Aoostar TB4S-OC (OCuLink) | ZFS RAIDZ1 | ~5.5TB usable |
| `Arctic-Storage` | 1× Crucial P510 2TB PCIe Gen5 NVMe | btrfs | 2TB |
| `ironwolf` | 4× Seagate IronWolf 4TB SATA HDD | btrfs RAID5 | ~12TB usable |

---

## Hardware

| Component | Choice |
|---|---|
| **Base unit** | ZimaCube 2 Standard — i3-1215U · 32GB DDR5 dual-channel · ZimaOS |
| **OS drive** | Kingston 256GB PCIe Gen4 NVMe |
| **Fast NVMe** | Crucial P510 2TB PCIe Gen5 (onboard M.2, PCIe 3.0 x2 since Phase 1.8) |
| **NVMe RAID** | 4× 2TB PCIe Gen4 NVMe via Aoostar TB4S-OC (OCuLink) |
| **SATA HDDs** | 4× Seagate IronWolf 4TB — `ironwolf` btrfs RAID5, 12TB usable (created June 24, 2026) |
| **Network** | 2× Intel i226 2.5GbE — 1 port active → Ubiquiti Flex Mini 2.5G |

---

## Phases

Use the **Build Phases** menu to navigate the full documentation for each phase — including setup steps, troubleshooting notes, and honest friction logs.
