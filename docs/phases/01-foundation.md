# ZimaCube 2 Build — Phase 1: Foundation, Storage & Benchmarks

**Author:** ted-knight  
**Status:** 🟡 In Progress  
**Started:** May 21, 2026  
**Updated:** June 03, 2026  
**Program:** ZimaCube 2 Pioneer Program  

---

## Table of Contents

1. [Goal](#goal)
2. [Completed and Pending](#completed-and-pending)
3. [Build Journey](#build-journey)
4. [Final Hardware Configuration](#final-hardware-configuration)
5. [Storage Architecture](#storage-architecture)
6. [Thunderbolt 4 Issue and OCuLink Resolution](#thunderbolt-4-issue-and-oculink-resolution)
7. [ZFS Pool Setup](#zfs-pool-setup)
8. [ZimaOS Integration](#zimaos-integration)
9. [Arctic-Storage Setup](#arctic-storage-setup)
10. [Benchmark Methodology](#benchmark-methodology)
11. [Benchmark Results](#benchmark-results)
12. [Analysis](#analysis)
13. [ZFS ARC Tuning](#zfs-arc-tuning)
14. [Recommended Workload Split](#recommended-workload-split)
15. [Immich Migration](#immich-migration)
16. [ZimaOS Observations](#zimaos-observations)
17. [Honest Friction Log](#honest-friction-log)
18. [What's Coming Next](#whats-coming-next)
19. [Benchmark Scripts](#benchmark-scripts)
20. [System Information](#system-information)
21. [Resources](#resources)

---

## Goal
*Build a stable and power efficient NAS; tiered storage foundation with redundancy, snapshots, and core services running on ZimaOS. Document the journey — including new discovery and what went wrong — from Phase 1 through Phase 6. After much deliberation, the choice of consumer NAS is the [ZimaCube 2 Standard NAS](https://shop.zimaspace.com/products/zimacube-2-personal-cloud-nas).*

---

### ZimaCube 2 Standard NAS
*It came in a nice huge black box with an orange accent.*
![ZimaCube 2 Box](../images/phase1.5/day02-zimacube2-box-01.jpg)

*Front panel of ZimaCube 2 standard with 2x USB-A 3.0, 1x USB-C 3.0, 1x 3.5mm Audio Jack and a small Power Button.*
![ZimaCube 2 Front](../images/phase1.5/day02-zimacube2-front-panel-01.jpg)

*Front Bay of ZimaCube 2 supporting 6x SATA3 3.5"/2.5" HDD trays + 7th tray supporting 4x M.2 NVMe SDDs.*
![ZimaCube 2 Front Bays 01](../images/phase1.5/day02-drive-bays-loaded-01.jpg)
![ZimaCube 2 Front Bays 02](../images/phase1.5/day02-drive-bays-loaded-02.jpg)

*Front HDD Tray with LED status/activity lights.*
![ZimaCube 2 Front Bay Tray](../images/phase1.5/day02-drive-bay-tray-closeup-01.jpg)

*ZimaCube 2 — featuring a sleek silver chassis with sharp angular lines. Its understated design ensures it blends seamlessly into any space without drawing attention.*
![ZimaCube 2 Side](../images/phase1.5/day02-zimacube2-exterior-side-01.jpg)

*ZimaCube 2's minimalist back panel neatly hides its dual exhaust system, keeping the focus on sleek aesthetics rather than hardware clutter.*
![ZimaCube 2 Rear](../images/phase1.5/day02-zimacube2-rear-panel-01.jpg)

*Pin-hole reset, 19V DC Power input, 2x Thunderbolt 4 or USB4-capable USB-C connections (direct attached network for compatible devices), 2x 2.5GbE network ports, 2x USB-A 3.0, 1x Display Port 1.4 and 1x HDMI 2.0*
![ZimaCube 2 Rear Ports](../images/phase1.5/day02-zimacube2-rear-panel-02.jpg)
> **For the keen eyes:** The IO shield of the ZimaCube 2 Standard came slightly displaced at the upper left. I have to open the upper shell to access the internal of ZimaCube 2 to readjust the IO shield. Could be due to shipping, it got moved.
---

### ZimaCube 2 Standard NAS (Internal)
*Unscrewing the ZimaCube 2 with the provided screwdriver to access the top panel.*
![ZimaCube 2 Unscrew 01](../images/phase1.5/day02-case-opening-screw-removal-01.jpg)
![ZimaCube 2 Unscrew 02](../images/phase1.5/day02-case-opening-screw-removal-02.jpg)

*Top overview of ZimaCube 2. First thing I have noticed is the huge CPU cooler for mobile Intel Core i3-1215U. That should ensure a cool quiet operation.*
![ZimaCube 2 Interior Top](../images/phase1.5/day02-interior-overview-01.jpg)

*The original 1x Samsung 8GB SODIMM DDR5 4800 MT/s stick.*
![ZimaCube 2 Interior Original RAM](../images/phase1.5/day02-interior-original-ram-01.jpg)

*The original 1x Kingston 256GB PCIe4 NVMe SDD used as bootdrive and home to ZimaOS Plus.*
![ZimaCube 2 Interior Original NVMe M2 SSD](../images/phase1.5/day02-interior-original-m2-ssd-01.jpg)

*Both Standard and Pro versions of the ZimaCube 2 feature versatile expansion options with one PCIe4 x4 lane (physical x16 slot) and one PCIe3 x2 lane (physical x8 slot). This configuration ensures broad compatibility with most add-on cards, provided they are low-profile to fit within the chassis dimensions.*
![ZimaCube 2 Interior Original PCIe Slots](../images/phase1.5/day02-pcie-card-install-01.jpg)

*The illuminated 7th bay of the ZimaCube 2 offers versatility—transform your system into an all-flash NVMe NAS with ease.*
![ZimaCube 2 Interior Original 7th Bay Tray 01](../images/phase1.5/day02-nvme-adapter-card-top-01.jpg)
![ZimaCube 2 Interior Original 7th Bay Tray 02](../images/phase1.5/day02-nvme-adapter-card-slots-01.jpg)
---

### Components used for Upgrade journey
![ZimaCube 2 Upgrades](../images/phase1.5/day02-upgrades-components-spread-01.jpg)

*Expand Tier 1 - Fast NVMe storage of my ZimaCube 2 from the original 256GB to additional 2TB to house folders such as AppData, Docker images, User DBs and other active workloads.*
![Crucial P510 2TB PCIe5 NVMe 2280 M.2 SSD Box](../images/phase1.5/day02-crucial-p510-nvme-box-01.jpg)

*While a PCIe5 NVMe is overkill, it happened to be the best-priced option available given current market conditions.*
![Crucial P510 2TB PCIe5 NVMe 2280 M.2 SSD Stick](../images/phase1.5/day02-crucial-p510-nvme-unboxed-01.jpg)

*The PCIe x4 to OCuLink SFF-8612 adapter — the solution after Thunderbolt 4 failed to establish a stable connection with the Aoostar TB4S-OC. Installed in Slot 1, this card provides a direct PCIe link to the 4× NVMe enclosure with no tunnelling protocol or firmware handshake required, forming the backbone of the glacier ZFS RAIDZ1 Tier 2 pool.*
![OCuLink PCIe x4 to SFF-8612 adapter](../images/phase1.5/day02-oculink-pcie-card-01.jpg)

*Solving the ZimaCube 2's 7th tray limitation with a Thunderbolt4 + OCuLink DAS solution. Read the full review of this unit at NASCompares.com. [NASCompares_TB4S-OC Review](https://nascompares.com/2024/10/09/aoostar-tb4s-oc-review/)*
![Aoostar TB4S-0C USB4 OCuLink NVMe enclosure](../images/phase1.5/aoostar-tb4s-oc-nvme-enclosure.png)
---

## Completed and Pending
### ✅ Completed

- [x] ZimaCube 2 Standard received and powered on
- [x] RAM upgraded: 8GB → 16GB DDR5 (Crucial 5600MHz CL46 SODIMM)
- [x] Crucial P510 2TB PCIe Gen5 installed in 7th Bay → Arctic-Storage (btrfs)
- [x] AppData + User Database migrated from ZimaOS-HD to Arctic-Storage via ZimaOS GUI migration tool
- [x] PCIe x4 → SFF-8612 OCuLink adapter installed in Slot 1
- [x] Aoostar TB4S-OC connected via OCuLink (TB4 abandoned — see [Thunderbolt 4 Issue](#thunderbolt-4-issue-and-oculink-resolution))
- [x] All 4× 2TB NVMe drives detected (nvme1n1–nvme4n1)
- [x] Glacier ZFS RAIDZ1 pool created at `/media/glacier`
- [x] 7 ZFS datasets created (VM, appdata, backup, documents, downloads, gallery, media)
- [x] ZimaOS symlinks created: `/DATA/glacier-*` → `/media/glacier/*`
- [x] Autotrim enabled on glacier pool
- [x] Full storage benchmarks completed (glacier vs Arctic-Storage)
- [x] Immich migrated from DIY ZimaOS — 14,505 photos + 925 videos (134 GiB), all memories/metadata intact (see [Phase 2.5](02.5-immich.md))
- [x] ZFS ARC behaviour verified: **93.7% hit rate**, c_max auto-set to 14.37 GiB

### ⏳ Pending

- [ ] **[Planned]** ZimaOS dashboard currently shows ~78% RAM used — this reflects ZFS ARC holding up to its 14.37 GiB c_max ceiling, not actual application memory pressure. Observing whether ARC naturally yields memory as Phase 2 Jellyfin workloads ramp up. Will cap ZFS ARC at 8 GiB if memory contention becomes an issue.
- [ ] RAM → 32GB DDR5 (2× Corsair Vengeance 16GB DDR5 4800MHz CL40 SODIMM) → raise ARC cap to 16 GiB after upgrade
- [ ] Move Crucial P510 to onboard M.2 slot → Phase 1.5 re-benchmark
- [ ] **[TBD]** TB4 direct networking test — connect Mac/PC via TB4 cable, configure IP over Thunderbolt, benchmark vs 2.5GbE
- [ ] Phase 1 Reddit post

---

## Build Journey

This build started as a **standard ZimaCube 2 with 8GB RAM** — the base configuration fresh out of the box. Over a single weekend, it was upgraded significantly into a proper modest homelab NAS machine.

The choice of ZimaOS was deliberate — after years with Synology, the simplicity of ZimaOS combined with its Docker-focused app deployment model made it the natural replacement. Everything runs as a container, the UI stays clean, and the OS stays out of the way. I have been a longtime fan of CasaOS (straight forward simplicity) and when ZimaOS came out, it was a no brainer for me to hopped on the bandwagon.

### Upgrades Made This Weekend

**1. RAM Upgrade**  
Replaced the stock 8GB DDR5 with a **Crucial 16GB DDR5 5600MHz CL46 SODIMM**. Planning to upgrade further with **2× Corsair Vengeance 16GB DDR5 4800MHz CL40 SODIMM** for a total of **32GB DDR5**.

*Removing the original 1x Samsung 8GB SODIMM DDR5 4800 MT/s stick.*
![ZimaCube 2 Interior - Removing Original RAM](../images/phase1.5/day02-ram-upgrade-removing-old-01.jpg)

*Installing the new 1x Crucial 16GB SODIMM DDR5 4800 MT/s stick.*
![ZimaCube 2 Interior - Removing Original RAM](../images/phase1.5/day02-ram-upgrade-installing-new-01.jpg)
> **Note:** The ZimaCube 2 Standard supports up to **64GB DDR5** (2× 32GB SODIMM). The planned 2× 16GB Corsair Vengeance upgrade brings it to 32GB — a second upgrade to 2× 32GB SODIMM is possible if more RAM is ever needed in future direction of ZimaCube 2. Right now, 16GB DDR5 is the sweet spot.

**2. Internal NVMe — Crucial P510 2TB PCIe 5.0 (7th Bay)**  
Installed a Crucial P510 2TB Gen5 NVMe M.2 2280 into the ZimaCube 2's internal 7th Bay NVMe enclosure. Formatted as native ZimaOS btrfs, named **Arctic-Storage** (`nvme0n1`). ZimaOS App Data and User Database migrated here from the Kingston OS drive (`nvme5n1`) via the built-in migration tool.

*Installing the Crucial P510 2TB PCIe Gen5 installed in 7th Bay NVME1 → configured as Arctic-Storage (btrfs)*
![ZimaCube 2 Interior - Inserting new NVMe SSD](../images/phase1.5/day02-nvme-ssd-install-inserting-01.jpg)
![ZimaCube 2 Interior - Installed new NVMe SSD](../images/phase1.5/day02-nvme-ssd-install-complete-01.jpg)
![ZimaCube 2 Interior - Seated new NVMe SSD](../images/phase1.5/day02-nvme-ssd-install-seated-01.jpg)
> ⚠️ **Note:** The 7th Bay on the ZimaCube 2 Standard is capped at 800 MB/s total by the ASMedia bridge — the PCIe 5.0 speed of the Crucial P510 drive is completely wasted here sequentially. A cheaper PCIe 3.0 or 4.0 drive delivers identical sequential performance in this slot. However, random IOPS are unaffected by the bridge cap, making the 205K IOPS and 0.6ms latency of the P510 genuinely useful for Docker app workloads.

> 🔬 **Planned experiment — Phase 1.5:** I'm moving the Cruial P510 from the ZimaCube 2's 7th bay to the onboard M.2 slot to test whether it can achieve native PCIe 5.0 speeds. Re-benchmark results will follow once complete.

**3. PCIe OCuLink Adapter**  
Installed a **PCIe x4 to SFF-8612 adapter** into Slot 1 of ZimaCube 2. Slot 1 is a physical x16 slot wired at PCIe 4.0 x4 lanes (~8 GB/s) — the card fits a full-length x16 form factor but only uses four lanes electrically.

*Install PCIe OCuLink Adapter*
![ZimaCube 2 Interior - Install PCIe OCuLink Adapter 01](../images/phase1.5/day02-pcie-card-install-02.jpg)
![ZimaCube 2 Interior - Install PCIe OCuLink Adapter 02](../images/phase1.5/day02-pcie-card-install-03.jpg)
> 💡 **Implication:** With Slot 1 occupied by the OCuLink adapter, both Thunderbolt 4 ports on the ZimaCube 2 are now free — available for a **TB4 eGPU dock** (Phase 4b) or **TB4 direct networking** to a Mac/PC for high-speed file transfer beyond the 2.5GbE ceiling.

**4. Aoostar TB4S-OC NVMe Enclosure (OCuLink)**  
Connected the **Aoostar TB4S-OC** (USB4/Thunderbolt 4 + OCuLink NVMe DAS) via OCuLink after Thunderbolt 4 failed (see [Thunderbolt 4 Issue](#thunderbolt-4-issue-and-oculink-resolution)). The enclosure holds **4× 2TB PCIe Gen4 NVMe M.2 SSDs** (`nvme1n1`–`nvme4n1`), formatted as **ZFS RAIDZ1** named **glacier**.

*Aoostar TB4S-OC NVMe Enclosure (OCuLink) seated on top of ZimaCube 2*
![ZimaCube 2 - Aoostar TB4S-OC NVMe Enclosure 01](../images/phase1.5/day02-zimadock-setup-top-01.jpg)
![ZimaCube 2 - Aoostar TB4S-OC NVMe Enclosure 02](../images/phase1.5/day02-zimadock-powered-on-01.jpg)
![ZimaCube 2 - Aoostar TB4S-OC NVMe Enclosure 03](../images/phase1.5/day02-rear-cables-connected-01.jpg)
![ZimaCube 2 - Aoostar TB4S-OC NVMe Enclosure 04](../images/phase1.5/day02-rear-display-ports-cabled-01.jpg)

**5. USB Storage (Temporary)**  
Two portable SSDs connected via USB ports while waiting for SATA HDDs to arrive:
- **Transcend ESD310C 1TB** — USB 10Gbps, dual Type-C/Type-A (`sda`)
- **SanDisk Portable SSD SDSSDE30 1TB** — USB 3.2 Gen 2, up to 800 MB/s (`sdb`)

**Coming soon:** 4× Seagate IronWolf 4TB 3.5" SATA NAS drives (5,400 RPM, CMR, 256MB cache) for the `ironwolf` btrfs RAID5 pool (~12TB usable) in the 6 SATA bays — bulk media files, movies, TV shows, photos archive. 1 drive received; 3 in transit.

---

## Final Hardware Configuration

### ZimaCube 2 Standard — Complete Spec

| Component | Specification |
|---|---|
| Model | ZimaCube 2 (Standard) |
| CPU | Intel Core i3-1215U (12th Gen Alder Lake, 6-core) |
| RAM | 16GB DDR5 — Crucial 5600MHz CL46 SODIMM |
| RAM (planned) | 2× 16GB Corsair Vengeance DDR5 4800MHz CL40 SODIMM = **32GB DDR5** (max supported: 64GB via 2× 32GB SODIMM) |
| OS | ZimaOS (Buildroot-based, immutable, RAUC A/B OTA) |
| Network | 2× Intel i226 2.5GbE | 1 port active → Ubiquiti Flex Mini 2.5G 5-Port Managed Switch · 2nd port unused (no current use case — to explore in future) |
| Thunderbolt | 2× Thunderbolt 4 ports (both free — eGPU or direct networking use) |
| PCIe Slot 1 | Physical x16 slot · PCIe 4.0 x4 lanes → OCuLink SFF-8612 adapter |
| PCIe Slot 2 | Physical x8 slot · PCIe 3.0 x2 lanes → **available — reserved for future 10GbE NIC upgrade** |
| 7th Bay | 4× M.2 NVMe slots (800 MB/s total bridge cap on Standard) |
| Onboard M.2 | Additional slot available → planned P510 migration (Phase 1.5) |
| SATA Bays | 6× 3.5"/2.5" SATA bays (empty — drives arriving soon) |

> **Standard vs Pro:** The ZimaCube 2 Standard uses the same 7th Bay physical layout as the Pro, but the ASMedia bridge limits total 7th Bay bandwidth to 800 MB/s (vs 3,200 MB/s on Pro/Creator). Standard has 2.5GbE-only network (no 10GbE) and an i3-1215U vs the Pro's i5-1235U.

### NVMe Drive Inventory

| Device | Model | Capacity | Interface | Location | Role |
|---|---|---|---|---|---|
| `nvme5n1` | Kingston OM8PGP4 256GB | 256GB | PCIe Gen4 | Onboard M.2 | ZimaOS boot drive |
| `nvme0n1` | Crucial P510 (CT2000P510SSD8) | 2TB | PCIe Gen5 | 7th Bay Slot 1 | Arctic-Storage (btrfs) — may move to onboard slot |
| `nvme1n1` | ORICO 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | glacier ZFS RAIDZ1 |
| `nvme2n1` | ORICO 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | glacier ZFS RAIDZ1 |
| `nvme3n1` | XPG GAMMIX S70 BLADE 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | glacier ZFS RAIDZ1 |
| `nvme4n1` | XPG GAMMIX S70 BLADE 2TB | 2TB | PCIe Gen4 | Aoostar TB4S-OC | glacier ZFS RAIDZ1 |

### Full `nvme list` Output

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
| Seagate IronWolf × 4 | 4TB, 3.5", SATA 6Gb/s, 5,400 RPM, CMR, 256MB cache | Cold storage RAID5—ideal for bulk media. I chose the non-Pro Ironwolf model specifically for lower power consumption and quieter operation at 5,400 RPM |
| Corsair Vengeance × 2 | 16GB DDR5 4800MHz CL40 SODIMM | RAM upgrade 16GB → 32GB DDR5. Likely during Phase 4 - Local AI hosting |

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
    └── 4× Seagate IronWolf 4TB 3.5" SATA     ironwolf (btrfs RAID5, ~12TB usable)
```

---

## Thunderbolt 4 Issue and OCuLink Resolution

### What Happened

The Aoostar TB4S-OC was originally intended to connect via Thunderbolt 4. After extensive troubleshooting across multiple sessions — two 40GBps 240W USB-C cables, both ports tested, external power confirmed — the connection failed consistently with the following kernel errors:

```
thunderbolt: tb_path_activate+0x100/0x350 [thunderbolt]
thunderbolt 0000:00:0d.2: 0:8 <-> 1:3 (PCI): activation failed
thunderbolt 1-1: reading DROM failed: -107
thunderbolt 1-1: failed to initialize port 1
[endless retimer connect/disconnect loop in dmesg]
```

### Possible Root Causes

| Issue | Detail |
|---|---|
| `thunderbolt.host_reset=false` | ZimaOS kernel boot parameter — TB controller won't reset when a new device is plugged in |
| `security=user` on both TB domains | All TB devices require manual authorization before PCIe tunneling; device never enumerated to authorize |
| `DROM failed: -107 (ENOTCONN)` | ASMedia ASM2462PDX inside Aoostar can't complete DROM handshake with ZimaCube 2 TB controller |
| One TB port dead at boot | `0000:00:0d.3: 0:1: failed to reach state TB_PORT_UP. Ignoring port` |

### Resolution

Installed a **PCIe x4 → SFF-8612 OCuLink adapter** in Slot 1. All 4 drives detected on first boot. Zero configuration needed.

### Downstream Impact on Phase 4b eGPU

With PCIe Slot 1 occupied by the OCuLink adapter:
- Unable to use ~~Minisforum DEG1~~ (OCuLink-only) → ruled out as Slot 1 OCuLink connection is occupied by Aoostar TB4S-OC DAS
- Both TB4 ports now free → exploring to purchase **Minisforum DEG2** (TB5 + OCuLink) or an Aoostar AG02/AG03 TB4/TB5 eGPU dock as the viable paths for Phase 4b

### Troubleshooting Takeaway (To be verified with other enclosures)

If connecting an Aoostar TB4S-OC (or any ASM2462PDX-based NVMe enclosure) to a ZimaCube 2 — **use OCuLink, not Thunderbolt 4**. Direct PCIe via OCuLink means no tunneling protocol, no authorization requirements, no firmware handshake. It also delivers lower latency than TB4 tunneling.

### TB4 Peer-to-Peer Networking — Planned Experiment

The TB4 failure above was specific to PCIe tunneling to an external NVMe enclosure. A completely separate TB4 capability — **IP over Thunderbolt (TB4 direct connection)** — remains available and untested.

By connecting a Mac or PC directly to one of ZimaCube 2's TB4 ports with a single cable, the OS on both ends creates a high-speed point-to-point network link. This bypasses the 2.5GbE bottleneck entirely:

| Link | Effective bandwidth | Glacier seq. read accessible | Arctic seq. read accessible |
|---|---|---|---|
| 2.5GbE (current) | ~312 MB/s | 12% of 2,591 MB/s | 36% of 874 MB/s |
| TB4 networking (~10–20Gbps) | 1,250–2,500 MB/s | 48–96% of 2,591 MB/s | ~100% of 874 MB/s |

For workloads like pulling raw photos from Immich, streaming high-bitrate media, or running Ollama inference from a client machine, the 2.5GbE link is the real throughput ceiling — not the storage. TB4 networking removes that ceiling for a directly-connected machine.

> ⚠️ **Caveats to test:**
> - ZimaOS's `security=user` TB policy requires manual device authorization via `boltctl enroll` — this may need to be run once per connected machine.
> - One TB4 port was dead at boot during the Aoostar investigation (`0000:00:0d.3: 0:1: failed to reach state TB_PORT_UP`). Will verify whether either or both ports work for peer-to-peer.
> - IP over Thunderbolt on ZimaOS (Buildroot) needs kernel module confirmation (`thunderbolt_net` / `apple-tbnet`).

---

## ZFS Pool Setup

### Why ZFS RAIDZ1

| Factor | Decision |
|---|---|
| Data integrity | ZFS checksums detect and self-heal silent corruption — critical for photo and document storage |
| Redundancy | RAIDZ1 survives 1 drive failure across 4 drives |
| Snapshots | Copy-on-write snapshots are instant — essential before Phase 4 experiments |
| Compression | lz4 is near-zero CPU cost on i3-1215U with real savings on documents and logs |

### Why btrfs for Arctic-Storage and ironwolf

Both `Arctic-Storage` and `ironwolf` are formatted as **btrfs** — ZimaOS's native filesystem. This is a deliberate choice to stay within the ZimaOS ecosystem for these two pools, prioritising seamless UI integration over the advanced features ZFS offers.

| Pool | Configuration | Reason for btrfs |
|---|---|---|
| `Arctic-Storage` | Single drive (Crucial P510 2TB) | ZimaOS recognises btrfs volumes natively — the Storage app, Files app, and AppData migration tool all work without any manual symlinks or workarounds |
| `ironwolf` | 4× Seagate IronWolf 4TB — btrfs RAID5 | Configured via ZimaOS Storage Manager UI — same native recognition as Arctic-Storage; no CLI required to set up or manage the array |

**What this gives in practice:**

- **ZimaOS Storage app** — both pools appear in the dashboard with health status and usage at a glance
- **ZimaOS Files app** — browse, upload, and manage files on both pools directly through the web UI
- **AppData migration tool** — Settings → Storage → Apps can move Docker container data between these pools without manual intervention
- **No symlink workarounds needed** — unlike glacier (CLI-created ZFS pool), btrfs pools are first-class citizens in ZimaOS

> **The trade-off:** btrfs lacks ZFS's self-healing checksums and copy-on-write snapshot depth. For `Arctic-Storage` (active app data) and `ironwolf` (bulk media), the ZimaOS integration benefit outweighs the ZFS feature gap — especially since `glacier` already handles the workloads where data integrity is non-negotiable.

### Pool Creation

```bash
sudo -i

# Wipe drives first (removes any previous partition tables or ZFS labels)
dd if=/dev/zero of=/dev/nvme1n1 bs=1M count=10
dd if=/dev/zero of=/dev/nvme2n1 bs=1M count=10
dd if=/dev/zero of=/dev/nvme3n1 bs=1M count=10
dd if=/dev/zero of=/dev/nvme4n1 bs=1M count=10

# Create pool
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

# Enable autotrim (NVMe health)
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

### Pool Health

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

## ZimaOS Integration

### Why CLI-Created ZFS Pools Don't Appear in the UI

ZimaOS only recognises storage pools and drives that were created or configured through its own Storage Manager UI. ZFS pools created via CLI — like `glacier` — are invisible to the storage dashboard and the AppData migration tool. This is a known limitation with multiple open feature requests on ZimaOS GitHub: [#423 — ZFS RAIDZ Support](https://github.com/IceWhaleTech/ZimaOS/issues/423), [#216 — ZFS Web GUI configuration](https://github.com/IceWhaleTech/ZimaOS/issues/216), [#298 — Local mountpoints in Storage Management](https://github.com/IceWhaleTech/ZimaOS/issues/298).

> **Alternative approach for Proxmox-hosted ZimaOS:** When running ZimaOS as a Proxmox VM, there is a workaround that achieves native pool recognition without symlinks. Create the ZFS pool directly in the Proxmox Shell using the same CLI commands as above, then present the pool to the ZimaOS VM as a virtual SCSI disk. ZimaOS treats it like any other block device — the same way it sees the Crucial P510 NVMe — and the Storage Manager picks it up natively. This was discovered while setting up a DIY ZimaOS instance on Proxmox and is not applicable to bare-metal installs like the ZimaCube 2, but is worth knowing for anyone running ZimaOS virtualised.

### Solution — Symlinks in /DATA

Creating symlinks in `/DATA` makes datasets appear in the ZimaOS Files app as if they were native volumes:

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

## Arctic-Storage Setup

The Crucial P510 2TB PCIe Gen5 was installed in the 7th Bay and formatted via the ZimaOS GUI — ZimaOS automatically formatted it as **btrfs** and named it Arctic-Storage. Using btrfs here (rather than ZFS) gives it native ZimaOS UI recognition: the storage dashboard, Apps migration tool, and Docker volume mounts all work without any symlink workarounds.

AppData was migrated from ZimaOS-HD to Arctic-Storage using **Settings → Storage → Apps** — ZimaOS handles the symlinks automatically, and all apps continued working immediately.

> ⚠️ **7th Bay bandwidth cap:** The ZimaCube 2 Standard caps the 7th Bay at 800 MB/s total via its ASMedia bridge. The P510 is capable of 9,000+ MB/s natively but is bridge-limited here. Both sequential read (874 MB/s) and write (788 MB/s) hit this ceiling. Random IOPS are unaffected — the 205,588 IOPS and 0.6ms latency of the P510 are fully available for Docker workloads.

> 🔬 **Planned — Phase 1.5:** Move P510 to the additional onboard M.2 slot to test native PCIe Gen5 sequential speed. Re-benchmark and compare.

---

## Benchmark Methodology

### Tool

`fio 3.38` — natively available on ZimaOS Buildroot. No installation required; confirmed with `fio --version` in the web terminal.

> **Note:** ZimaOS is Buildroot-based with no `apt`, `yum`, or package manager. `fio`, `zpool`, `zfs`, `nvme`, and `iostat` are available natively. All other software runs as Docker containers.

### Terminal Access

ZimaOS does not expose SSH by default. The web-based terminal was accessed via:

1. Open ZimaOS **Settings**
2. Navigate to **General → Developer Mode**
3. Click **View** to open the Developer panel
4. Launch the **Web-based terminal**

All commands were run as root:

```bash
sudo -i
```

### Script Deployment via WinSCP

The benchmark scripts (maintained in this repo under [`docs/resources/scripts/`](../resources/scripts/)) were uploaded from the Windows host to ZimaCube using **WinSCP**:

| | Path |
|---|---|
| **Local (repo)** | `docs/resources/scripts/` |
| **Remote (ZimaCube)** | `/DATA/Documents/nvme-benchmark/` |

WinSCP connection: host `192.168.xxx.xxx` · Protocol: SFTP · Port 22

Files uploaded:
- [`benchmark-glacier.sh`](../resources/scripts/benchmark-glacier.sh)
- [`benchmark-arctic.sh`](../resources/scripts/benchmark-arctic.sh)
- [`benchmark-compare.sh`](../resources/scripts/benchmark-compare.sh)

### Execution

Scripts were run individually from the web terminal:

```bash
sudo -i
cd /DATA/Documents/nvme-benchmark

chmod +x benchmark-glacier.sh benchmark-arctic.sh benchmark-compare.sh

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

All tests: `--direct=1` (bypasses OS page cache) · `--ioengine=libaio`

### Monitoring

Real-time system metrics monitored via **btop** — installed from the ZimaOS App Marketplace.

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

With 4 drives in RAIDZ1, ZFS stripes reads across all drives simultaneously. The 2,591 MB/s sequential read result is **approximately 81% of the theoretical 3,200 MB/s OCuLink ceiling** — demonstrating near-optimal read distribution across all 4 drives. The remaining ~19% gap is expected ZFS overhead: metadata management, checksum verification, and stripe coordination.

Sequential write at 1,726 MB/s is strong given RAIDZ1 parity overhead, which adds one parity block per stripe across every write.

Arctic-Storage sequential results confirm the 800 MB/s Standard 7th Bay bridge cap — both read (874 MB/s) and write (788 MB/s) are bottlenecked by the ASMedia bridge hardware, not the PCIe 5.0 drive itself.

### Random IOPS — Arctic Dominates

Arctic-Storage delivers **205,588 IOPS** random 4K read at **0.6ms average latency** — completely unimpeded by the 7th Bay sequential cap. This is genuine PCIe 5.0 NVMe random I/O performance, and exactly why this slot makes sense for Docker app databases and inference model loading.

Glacier's 14,781 IOPS reflects ZFS RAIDZ1 copy-on-write overhead, parity calculation latency, and OCuLink tunnel baseline latency. These are **cold-cache numbers** — in practice, ZFS ARC (Adaptive Replacement Cache) will cache frequently accessed data in RAM, improving random read performance for real workloads over time.

### ZFS ARC — Measured Behaviour (June 3, 2026)

The fio benchmarks use `--direct=1` — bypassing the OS cache entirely. Real workloads go through ZFS ARC, which is the difference between the fio cold numbers and daily-use performance.

After 11 days of uptime, the measured ARC stats from `/proc/spl/kstat/zfs/arcstats`:

| Metric | Raw value | Human-readable |
|---|---|---|
| `size` (current ARC) | 10,004,018,376 | **9.32 GiB** |
| `c_max` (ARC ceiling) | 15,431,536,640 | **14.37 GiB** |
| `c_min` (ARC floor) | 515,789,952 | **492 MiB** |
| `hits` | 22,642,971 | reads served from RAM |
| `misses` | 1,529,588 | reads that went to NVMe |

**Hit rate: 93.7%** — 19 out of 20 glacier reads served directly from RAM, never touching NVMe.

`c_max` of 14.37 GiB is ZFS's default: **total RAM − 1 GB**. On a 15.3 GiB system that means ZFS can claim almost all of memory for cache. The ZimaOS dashboard widget reports 78% RAM used — alarming, but it counts ARC as "used." btop tells the real picture:

| btop metric | Value | Meaning |
|---|---|---|
| Used | 3.97 GiB | Actual application RAM |
| Cached | 11.4 GiB | ZFS ARC + Linux page cache |
| Available | 11.3 GiB | RAM available to apps on demand |

ARC is evicted immediately when applications need RAM — the system is not RAM-starved.

| RAM config | Practical ARC headroom | Impact |
|---|---|---|
| 16 GB (current) | ~8–10 GB | Hot Docker databases and small working sets |
| 32 GB (planned) | ~20–24 GB | Immich thumbnails + databases + Ollama model pages simultaneously |

### ZFS ARC — Warm Cache Benchmark Results (June 3–4, 2026)

To quantify the real-world ARC uplift, `benchmark-arc.sh` was run against glacier with an 8 GiB test file. The benchmark runs a full write + read suite: sequential write, random 4K write (both `--direct=1`), an ARC warm-up pass, then random 4K read with warm ARC and cold `--direct=1` baseline.

**Pre-benchmark ARC state (Day 12):**

| Metric | Value |
|---|---|
| `size` (ARC occupancy) | **9.32 GiB** (10,004,042,288 bytes) |
| `c_max` (ceiling) | **14.37 GiB** (15,431,536,640 bytes) |
| Cumulative hit rate | **93.7%** (22,688,107 hits / 1,529,589 misses) |

**Warm-up pass — sequential 8 GiB read (no `--direct=1`):**
- **3,329 MiB/s** (3,490 MB/s) — ZFS sequential prefetch pulled the 8 GiB test file into ARC in 2.4 seconds
- ARC size after warm-up: **8.70 GiB**

**Benchmark results — random 4K read, 4 jobs, `iodepth=32`, 60 seconds (Run 1):**

| Metric | Warm ARC (buffered) | Cold cache (`--direct=1`) | Uplift |
|---|---|---|---|
| **IOPS (avg)** | **83,416** | 16,276 | **5.1×** |
| **Bandwidth** | **326 MiB/s** (342 MB/s) | 63.6 MiB/s (66.7 MB/s) | **5.1×** |
| **Completion latency (avg)** | **1.49 ms** | **7.62 ms** | **5.1×** |
| 99th percentile latency | 2.11 ms | 8.98 ms | 4.2× |
| **99.99th percentile latency** | **4.49 ms** | **44.8 ms** | **10×** |
| I/O served in 60 s | 19.1 GiB | 3.7 GiB | 5.1× |

**Session ARC stats (warm benchmark only):**

| Metric | Value |
|---|---|
| Hits during test | 10,106,596 |
| Misses during test | 9,037 |
| **Session hit rate** | **99.9%** |
| ARC size after | 8.49 GiB |

99.9% of the 83K IOPS were served from RAM. The 9,037 misses (~150/sec) represent ZFS evicting a small fraction of existing cache entries to maintain the 8 GiB test file's working set at the ARC boundary.

**System impact during warm ARC benchmark (fio CPU stats + btop):**

| | Warm ARC | Cold (`--direct=1`) |
|---|---|---|
| CPU `sys` (fio processes) | 95.97% | 8.23% |
| Context switches | 6,370 | 954,944 |
| **Overall CPU (btop, during)** | **~55–56%** | — |
| CPU cores (peak, during) | multiple at **98–100%** | — |
| Temperature (peak, during) | **50–54°C** | — |
| After benchmark (idle) | **2–3%**, **32–35°C** | — |

ZFS serving 83K IOPS from ARC is CPU-intensive work — each read requires a kernel-space hash lookup, spinlock acquisition, and data copy from ARC buffer to userspace. The fio processes spent 96% of their CPU time in `sys` (kernel mode), and 4 jobs at ~12.5% each drove multiple cores to near-saturation. This is compute work, not I/O wait — which is why latency remains at 1.49 ms (ARC response time) rather than 7.62 ms (NVMe response time).

The cold pass tells the opposite story: 954,944 context switches across 976K I/Os — nearly one interrupt-driven context switch per request, as each read dispatched to the NVMe queue, waited for a hardware interrupt, and returned through the ZFS I/O pipeline. `z_rd_int` kernel threads appeared at the top of btop's process list during this pass, confirming real NVMe activity. The CPU recovered to 2–3% within 30 seconds of both tests completing.

**Run 2 — ARC cold-start (same night, ~12 minutes later):**

Between runs, the test file was deleted and ZFS evicted its cached data. ARC shrank from 8.49 GiB to **0.22 GiB** — confirming ZFS actively reclaims memory after data is no longer referenced, not just when under pressure.

| Metric | Run 1 (ARC = 9.32 GiB before) | Run 2 (ARC = 0.22 GiB before) |
|---|---|---|
| Warm-up speed | 3,329 MiB/s (2.4 s) | **4,298 MiB/s (1.9 s)** |
| Warm ARC IOPS (avg) | 83,416 | **83,707** (+0.4%) |
| Warm ARC latency (avg) | 1.49 ms | 1.48 ms |
| Session hit rate | 99.9% | **100.0%** |
| Misses during warm test | 9,037 | **2,603** |
| Cold IOPS (avg) | 16,276 | 18,315 |

Run 2 warm-up was 29% faster because no eviction work was needed — ARC had 14 GiB of headroom and filled freely. The warm ARC IOPS is within 0.4% between runs: the ceiling at 83–84K IOPS is consistent and reproducible regardless of starting ARC state. The 100.0% session hit rate in run 2 (vs 99.9%) reflects that the 8 GiB test file had exclusive ARC occupancy with zero competition.

Cold NVMe results show more run-to-run variance (16,276 vs 18,315 IOPS) than ARC-served results — NVMe I/O scheduling, NVMe queue state, and RAIDZ1 parity distribution vary more than ARC hash lookups.

> **Takeaway:** With a warm ARC, glacier behaves like an 83K IOPS RAM array, not a 16K IOPS NVMe RAIDZ1 — at the cost of ~55% CPU during sustained high-IOPS reads. Workloads with repeated access patterns — Immich metadata lookups, Jellyfin library scans, Nextcloud file indexing — will experience this warm-cache tier, not the cold-cache floor numbers. ZFS ARC also proves it evicts promptly: 8.49 GiB of cached data was fully released within 12 minutes of the test file being deleted.

**Runs 3 and 4 — cold baseline + ARC (June 3–4, 2026):**

Runs 3 and 4 paired `benchmark-glacier.sh` immediately before `benchmark-arc.sh` in the same session, giving a combined cold baseline + warm ARC picture for each night. Run 4 used the original 3-step ARC script; sequential write and random 4K write tests were added to `benchmark-arc.sh` after this run completed.

**`benchmark-glacier.sh` cold baseline:**

| Metric | Run 3 (June 3, 23:55) | Run 4 (June 4, 00:55) |
|---|---|---|
| Sequential write | 1,752 MiB/s (1,837 MB/s) | 1,685 MiB/s (1,767 MB/s) |
| Sequential read | 2,285 MiB/s (2,396 MB/s) | 2,375 MiB/s (2,491 MB/s) |
| Random 4K write | 13,725 IOPS | 13,387 IOPS |
| Random 4K read | 14,063 IOPS | 15,751 IOPS |

**Five-run ARC benchmark summary:**

| Metric | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 |
|---|---|---|---|---|---|
| ARC size before | 9.32 GiB | 0.22 GiB | 0.23 GiB | 0.23 GiB | 0.23 GiB |
| Warmup speed | 3,329 MiB/s | 4,298 MiB/s | 4,459 MiB/s | 4,328 MiB/s | 3,832 MiB/s² |
| **Warm ARC IOPS (avg)** | **83,416** | **83,707** | **83,588** | **83,929** | **83,858** |
| Warm ARC latency (avg) | 1.49 ms | 1.48 ms | 1.48 ms | 1.48 ms | 1.48 ms |
| Session hit rate | 99.9% | 100.0% | 100.0% | 100.0% | 99.4%³ |
| Misses during session | 9,037 | 2,603 | 2,001¹ | 2,001 | 67,392³ |
| Cold rand read IOPS | 16,276 | 18,315 | ~14,063 | 17,577 | 16,497 |
| Cold rand read latency | 7.62 ms | — | — | 7.05 ms | 7.52 ms |

¹ Runs 3–4 share ARC size before (0.23 GiB) and similar miss counts — ARC started near-empty each night after the previous run's test file was deleted and evicted.

² Run 5 warmup started with ARC already ~11.5 GiB (ZFS cached the sequentially written test file during the write tests). Evictions during the warmup pass produced lower throughput than a clean cold start.

³ Run 5 session hit rate and miss count cover the entire 7-step benchmark including write phases. ZFS performed ARC lookups during the write tests and the warmup needed to evict ~3 GiB of write-cached data, accounting for the extra 67K misses. The warm ARC rand read itself was as consistent as all prior runs.

Warm ARC IOPS spans **83,416–83,929 across five runs — under 0.6% variance**. Average latency is locked at 1.48–1.49 ms in every run. The ceiling is determined by kernel ARC lookup speed (hash table query + spinlock + DMA copy to userspace), not by NVMe or pool conditions.

Cold random IOPS spans 14K–18.3K across all runs — a wider band consistent with NVMe queue state, RAIDZ1 parity scheduling, and background system load varying between sessions. btop during warm ARC passes (Runs 1, 4, 5) consistently shows 58–64% overall CPU, multiple cores at 98–100%, Load AVG 4–5.5 — ARC serving 83K IOPS is CPU-intensive regardless of starting conditions.

**Write benchmarks — benchmark-arc.sh Run 5 (June 4, 01:17):**

Run 5 was the first run using the updated 7-step `benchmark-arc.sh` that includes sequential write and random 4K write tests (both `--direct=1`).

| Metric | Run 5 (`benchmark-arc.sh`) | Runs 3–4 (`benchmark-glacier.sh`) | Note |
|---|---|---|---|
| Sequential write | **1,679 MiB/s** (1,760 MB/s) | 1,685–1,752 MiB/s | Consistent — ARC has no effect on writes |
| Random 4K write | **9,883 IOPS** | 13,387–13,725 IOPS | **−26% lower** — see below |

Sequential write is consistent with `benchmark-glacier.sh` — as expected since ARC is not in the write path.

Random write IOPS is ~26% lower. The cause is **test sequencing with no recovery pause**: `benchmark-arc.sh` runs sequential write (4 jobs, 60 s, ~100 GiB total written looping over the 8 GiB file) immediately followed by random write. The NVMe drives' SLC write cache is still saturated when random write begins, depressing random IOPS. `benchmark-glacier.sh` runs a 60-second sequential read between its write tests, giving the SLC cache time to drain — its rand write figures are therefore more representative of sustained write performance.

Additionally, ZFS cached the sequentially written 8 GiB file in ARC during the seq write pass (`--direct=1` prevents OS page-cache use but does not block ZFS ARC caching): btop confirmed ARC grew from 0.23 GiB → ~11.5 GiB during the write tests. The subsequent warmup pass had to evict ~3 GiB of that write-cached data before the random read benchmark.

> Use `benchmark-glacier.sh` for the most representative standalone write numbers. The write tests in `benchmark-arc.sh` are included for completeness and are accurate for sequential write; the random write figures will be lower whenever they follow a heavy sequential write pass without a recovery period.

**btop observations during Run 5 write tests:**

| Phase | CPU | Notable processes | Peak temp |
|---|---|---|---|
| Sequential write (01:17:40) | ~48% | 4× `arc-seqwrite` at 10.4% each | **74°C** |
| Random write (01:18:28) | ~64% | `z_wr_iss` at 7.6–7.8%, 4× `arc-randwrite` at 1.7% | **74°C** |
| Warm ARC read (01:19:18) | ~58% | 4× `arc-randread` at 12.5%, Load AVG 5.56 | 58°C |
| Cold read (01:20:37) | ~9% | 4× `arc-randread` at ~1%, `z_rd_int` threads visible | 49°C |

74°C during writes is the highest temperature recorded across all benchmark sessions — ZFS RAIDZ1 CoW parity writes push the i3-1215U harder than read operations. `z_wr_iss` (ZFS write issue) threads dominating btop during random write confirms the bottleneck is in the ZFS write pipeline, not fio itself.

### The 14× IOPS Gap — Architectural, Not a Flaw

The Phase 1 benchmark showed a 14× random 4K IOPS gap between glacier (14,781 IOPS) and Arctic-Storage (205,588 IOPS). That gap exists for structural reasons, not defective hardware:

- **RAIDZ1 parity overhead.** Every random write to glacier triggers a full-stripe read-modify-write cycle — the existing parity block must be read and recalculated before the write can land. Arctic-Storage on a single btrfs drive has no parity to maintain.
- **Copy-on-write.** ZFS never overwrites in place. Each write allocates new blocks and updates the metadata tree, adding latency that a simpler filesystem at low queue depth avoids.
- **4K blocks don't stripe.** RAIDZ1 spreads data across four drives for sequential I/O — producing 2,591 MB/s sequential reads. A single 4K random block touches one drive; there is nothing to stripe. The RAIDZ1 advantage evaporates at small block sizes.
- **OCuLink hop.** The drives connect via PCIe 4.0 x4 through the Aoostar TB4S-OC enclosure. The tunnel adds a small but consistent baseline latency absent on onboard NVMe.

The ARC benchmark refines the picture. Cold — with `--direct=1` forcing every read to NVMe — glacier delivers 16K IOPS at 7.6ms latency. That is the floor. With a warm ARC, glacier delivers 83K IOPS at 1.5ms latency — a 5× uplift that narrows the gap to Arctic-Storage from 14× to roughly **2.5×**. For workloads that re-read the same data, the NVMe characteristics of glacier become largely irrelevant; the ARC is the actual storage layer.

The 2.5× warm gap that remains is real and appropriate to acknowledge. Immich's PostgreSQL engine performing random index lookups across 14,500 photos, or a Docker container reading configuration on every request, benefits from Arctic-Storage's 205K IOPS and 0.6ms latency in a way that no amount of ARC tuning will fully replicate on glacier. The correct response is not to close this gap — it is to route workloads by their I/O profile:

| I/O profile | Right pool | Reason |
|---|---|---|
| Random, latency-sensitive (databases, containers) | Arctic-Storage | 205K IOPS, 0.6ms — uncontested |
| Sequential, large files, redundancy required | glacier | 2,591 MB/s, RAIDZ1 integrity, ~5.5TB |
| Repeated reads, warm working set | glacier + ARC | 83K IOPS served from RAM |
| Cold bulk / media library | ironwolf (arriving) | Capacity and cost; sequential access only |

---

## ZFS ARC Tuning

### Why cap c_max now?

At 16 GB RAM, c_max defaulting to 14.37 GiB leaves only ~1 GB guaranteed for the OS + apps. ZFS is smart enough to evict ARC under memory pressure, but ZFS ARC eviction is slower than Linux page cache eviction. When Phase 2 lands and Jellyfin starts transcoding, ARC competing with a 831 MB+ process creates unnecessary pressure. Capping at 8 GiB gives glacier a generous read cache while guaranteeing ~7 GB headroom for all other workloads.

### How to check current ARC stats

```bash
# Raw stats — size, ceiling, floor, hits, misses
cat /proc/spl/kstat/zfs/arcstats | grep -E "^(size|c_max|c_min|hits|misses) "

# Hit rate in one line
awk '/^hits/{h=$3} /^misses/{m=$3} END{printf "ARC hit rate: %.1f%%\n", h/(h+m)*100}' \
    /proc/spl/kstat/zfs/arcstats
```

Measured output on Day 11 (June 3, 2026):
```
ARC hit rate: 93.7%
```

### Cap ARC at 8 GiB (current 16 GB system)

```bash
# Create or update the ZFS module config
echo "options zfs zfs_arc_max=8589934592" | sudo tee /etc/modprobe.d/zfs.conf

# Apply immediately — no reboot needed
echo 8589934592 | sudo tee /sys/module/zfs/parameters/zfs_arc_max

# Verify
cat /sys/module/zfs/parameters/zfs_arc_max
# Expected: 8589934592
```

The `/etc/modprobe.d/zfs.conf` entry ensures the cap survives reboots. The `/sys/module/...` write applies it live to the running kernel.

### After the 32 GB RAM upgrade

With 32 GB installed, raise the cap to 16 GiB — gives glacier a large cache while still leaving 14+ GB for Jellyfin, Immich, *arr, and future Ollama workloads:

```bash
# 16 GiB cap for 32 GB system (16 × 1024³ = 17179869184)
echo "options zfs zfs_arc_max=17179869184" | sudo tee /etc/modprobe.d/zfs.conf
echo 17179869184 | sudo tee /sys/module/zfs/parameters/zfs_arc_max
```

### ARC sizing reference

| RAM | Recommended c_max | Reasoning |
|---|---|---|
| 16 GB (current) | **8 GiB** | Half of RAM; leaves ~7 GB free for apps |
| 32 GB (planned) | **16 GiB** | Half of RAM; comfortable for Phase 4a Ollama inference |
| 32 GB + GPU workloads | **12 GiB** | Tighter if Ollama model loading competes for RAM |

### Benchmarking ARC performance

The standard fio suite uses `--direct=1` to measure raw NVMe speed — those are cold-cache floor numbers. To measure the real-world uplift from ZFS ARC, use the dedicated ARC benchmark script:

```bash
sudo -i
cd /DATA/Documents/nvme-benchmark
chmod +x benchmark-arc.sh
./benchmark-arc.sh
```

The script runs seven steps automatically:

1. **Capture ARC state before** — baseline hits, misses, cache size
2. **Sequential write** — `--direct=1`, 4 jobs, 1 M blocks, 60 s; bypasses OS page cache, measures raw ZFS pool write throughput
3. **Random 4K write** — `--direct=1`, 4 jobs, 4 K blocks, 60 s; ARC does not cache writes, so results are directly comparable to `benchmark-glacier.sh`
4. **Warm-up pass** — 8 GiB sequential read without `--direct=1` to populate ARC with the test file
5. **Warm ARC benchmark** — random 4K read without `--direct=1`; requests are served from RAM
6. **Capture ARC state after** — calculates session hit rate delta
7. **Cold reference** — same random 4K read with `--direct=1` to bypass ARC, for direct comparison

`zpool iostat glacier` runs in the background during step 5 — low disk read MB/s there confirms ARC was serving the requests, not the NVMe drives.

Results are saved to `/media/glacier/benchmark-results-arc.txt`. Expected outcome: warm ARC IOPS will be a multiple of the cold `--direct=1` baseline.

> The script source is at [`docs/resources/scripts/benchmark-arc.sh`](../resources/scripts/benchmark-arc.sh).

---

## Recommended Workload Split

> Full phase-by-phase breakdown (Phase 1 through Phase 6) is in [PHASE1-BENCHMARK.md — Recommended Workload Split](../benchmarks/PHASE1-BENCHMARK.md#recommended-workload-split).

### Phase 1 Summary

| Workload | Storage | Reason |
|---|---|---|
| ZimaOS system | `nvme5n1` (Kingston) | Boot stability, OS independence |
| Docker AppData (all containers) | Arctic-Storage | 205K IOPS, 0.6ms — random I/O dominant |
| Immich photo library files | Arctic-Storage | `/DATA/Gallery/immich` — standard ZimaOS path on P510 NVMe |
| Immich PostgreSQL database | Arctic-Storage | High random IOPS; ZFS ARC partially compensates but sub-ms beats 8.7ms |
| Immich ML model cache | Arctic-Storage | Low latency random reads for inference |
| VM disk images | glacier | Large sequential I/O, RAIDZ1 redundancy |
| Documents | glacier | ZFS checksums + snapshots for integrity |
| Cold media (arriving) | `ironwolf` | Capacity and cost-per-TB; sequential access only |

---

## Immich Migration ✅

Immich has been fully migrated from the DIY ZimaOS instance to ZimaCube 2. Full migration details and troubleshooting notes are in [Phase 2.5 — Immich](02.5-immich.md).

### Migration Status

- **Source:** DIY ZimaOS instance (LAN)
- **Destination:** ZimaCube 2 (LAN)
- **Volume:** 14,505 photos + 925 videos, 134 GiB — **zero data loss**
- **Method:** ZimaOS Files app LAN Storage copy of `/DATA/AppData/immich` + `/DATA/Gallery/immich`
- **Status:** ✅ Complete — all albums, faces, people, memories, and metadata intact

### Immich Architecture on ZimaCube 2

| Container | Version | Data Path |
|---|---|---|
| immich-server | v2.7.2 | `/DATA/Gallery/immich` |
| immich-postgres | 14-vectorchord0.4.3 | `/DATA/AppData/immich/pgdata` |
| immich-machine-learning | v2.7.2 | `/DATA/AppData/immich/model-cache` |
| immich-redis (valkey) | 8 | In-memory only |

> **Verified:** Database confirmed healthy via `ANALYZE` + `SELECT COUNT(*) FROM asset;` → 15,471 assets (14,505 photos + 925 videos + 41 motion photo components). `person`: 462, `album`: 7, `album_asset`: 1,652.

---

## ZimaOS Observations

ZimaOS is **Buildroot-based** with an immutable read-only OS. Key implications for homelab work:

| Fact | Impact |
|---|---|
| No apt/yum/package manager | All extra software runs as Docker containers or is natively available |
| `fio`, `zpool`, `zfs`, `nvme`, `iostat` available natively | Benchmarking and ZFS management work out of the box |
| ZFS pools created via CLI are invisible to the UI | Use symlinks in `/DATA` to expose datasets in the Files app |
| `thunderbolt.host_reset=false` in kernel boot | TB devices don't re-enumerate on plug-in — affects all TB connections |
| RAUC A/B OTA updates | Kernel updates are safe, but verify ZFS DKMS survives each update |
| AppData migration tool in Settings → Storage → Apps | Moves AppData/Docker images to any ZimaOS-recognised drive — symlinks created automatically |
| RAM widget shows 78% "used" with 16 GB | ZimaOS counts ZFS ARC cache as used RAM — misleading. Use btop or arcstats for the real picture. Available RAM was 11.3 GiB with 9.32 GiB absorbed by ARC |

---

## Honest Friction Log

- **TB4 failure** — biggest surprise. ZimaOS TB4 kernel config + ASMedia ASM2462PDX incompatibility = hours of troubleshooting. OCuLink was the right answer all along; skip straight to it on this hardware combination.
- **ZFS invisible to ZimaOS UI** — expected, but still a rough edge. The symlink workaround is functional but not elegant. Open feature request on ZimaOS GitHub.
- **Immich database empty after file migration** — moving photo files without moving the database gives you photos but no albums, faces, or metadata. The fix: copy the entire `/DATA/AppData/immich` folder (including `pgdata`) alongside the photo library. Stop Immich on the source first. See [Phase 2.5](02.5-immich.md) for the full method.
- **ZimaOS package manager missing** — `apt install fio` doesn't work. Discovering fio was already natively available saved the day; anything else requires Docker.
- **`hostname -I` not supported** — Buildroot's hostname binary doesn't support the `-I` flag. Use `ip addr` instead in scripts.
- **ZimaOS RAM widget shows 78% used** — alarming but misleading. ZimaOS counts ZFS ARC cache as "used" RAM. btop breaks it down correctly: 3.97 GiB actual app usage, 11.4 GiB ZFS ARC, 11.3 GiB available. ZFS will evict ARC immediately if applications need the memory. The fix is capping `c_max` to prevent ARC from ever growing past a sensible ceiling — see [ZFS ARC Tuning](#zfs-arc-tuning).

---

## What's Coming Next

### Planned Hardware Upgrades

| Upgrade | Detail | Impact |
|---|---|---|
| RAM → 32GB DDR5 | 2× Corsair Vengeance 16GB DDR5 4800MHz CL40 | Doubles ZFS ARC headroom; better VM and AI performance |
| P510 → onboard M.2 | Move Crucial P510 from 7th Bay to onboard slot | Unlock native PCIe Gen5 speeds — re-benchmark planned |
| 4× Seagate IronWolf 4TB | SATA bays — `ironwolf` pool (~12TB btrfs RAID5) | Bulk media archive tier; unblocks Phase 2 · 1 received, 3 in transit |
| eGPU dock (TBD) | Minisforum DEG2 (TB5+OCuLink) or TB4 eGPU enclosure | Phase 4b GPU inference — both TB4 ports now free |
| **10GbE NIC — PCIe Slot 2** | Intel X550-T1 (RJ45) or Mellanox MCX311A (SFP+) | 4× network uplift: 2.5GbE (~312 MB/s) → 10GbE (~1,100 MB/s) — when ZimaCube 2 is under heavier workload demand |

> 💡 **Future-proofing note — PCIe Slot 2:** The ZimaCube 2 Standard's PCIe 3.0 x2 slot (physical x8) has enough bandwidth (~2 GB/s) to run a 10GbE NIC at full line rate. Two viable card options:
>
> | Card | Interface | Cable to switch | Cost (used) |
> |---|---|---|---|
> | Intel X550-T1 | 10GBASE-T RJ45 | Cat6A → Port 9 RJ45 (10G COMBO) | ~$70–100 |
> | Mellanox ConnectX-3 MCX311A | SFP+ | DAC cable → Port 9 SFP+ (10G COMBO) | ~$25–35 |
>
> Both connect directly to the **Ubiquiti UniFi Flex 2.5G PoE** Port 9 (**10G COMBO** — has both RJ45 and SFP+ slots) with no adapters needed. The existing `i226` 2.5GbE port stays connected to one of the 8× access ports as a management/fallback link. PCIe Slot 2 remains empty until the NAS workload justifies the upgrade.

### Planned Experiments

- **Phase 1.5:** Move Crucial P510 to onboard M.2 slot → re-run `benchmark-arctic.sh` → publish comparison. Expected: sequential speeds climb from ~800 MB/s to 9,000+ MB/s; random IOPS similar.

- **TB4 direct networking:** Connect a Mac/PC directly to ZimaCube 2 via TB4 cable → configure IP over Thunderbolt on both ends → benchmark file transfer speeds. Goal: determine whether TB4 networking can unlock the full glacier sequential read (2,591 MB/s) and Arctic-Storage random IOPS for directly-connected clients, bypassing the 2.5GbE ceiling (~312 MB/s). Will also verify `boltctl` authorization flow on ZimaOS and which TB4 port is functional.

### Software Phases

| Phase | Description |
|---|---|
| **Phase 2** | Jellyfin media server — Intel QuickSync transcoding, `ironwolf` media library (on hold — SATA drives arriving) |
| **Phase 2.5** | Immich migration — 14,505 photos + 925 videos (134 GiB) from DIY ZimaOS to ZimaCube 2 via Arctic-Storage (`/DATA/Gallery/immich`) — ✅ complete |
| **Phase 3** | Personal cloud, Nextcloud, 3-2-1 backup strategy |
| **Phase 4a** | Ollama CPU-only AI baseline — i3-1215U inference benchmarks |
| **Phase 4b** | GPU-accelerated inference — RTX 4090 via TB4 eGPU or Minisforum DEG2 |
| **Phase 5** | Local AI semantic search across glacier storage (Khoj + Qdrant) |
| **Phase 6** | Steam Machine — bare metal Linux gaming |

---

## Benchmark Scripts

Available in [`docs/resources/scripts/`](../resources/scripts/):

| Script | Purpose |
|---|---|
| [`benchmark-glacier.sh`](../resources/scripts/benchmark-glacier.sh) | Full fio suite for glacier ZFS RAIDZ1 — 4 tests + pool stats |
| [`benchmark-arctic.sh`](../resources/scripts/benchmark-arctic.sh) | Full fio suite for Arctic-Storage btrfs — 4 tests + btrfs stats + NVMe SMART |
| [`benchmark-compare.sh`](../resources/scripts/benchmark-compare.sh) | Combined benchmark with side-by-side summary output |
| [`benchmark-arc.sh`](../resources/scripts/benchmark-arc.sh) | Full fio suite with ZFS ARC — seq write, rand write, warm ARC read, cold read + ARC hit rate delta |

Upload via **WinSCP** to `/DATA/Documents/nvme-benchmark/` on ZimaCube, then from the web terminal:

```bash
sudo -i
cd /DATA/Documents/nvme-benchmark
chmod +x benchmark-glacier.sh benchmark-arctic.sh benchmark-compare.sh benchmark-arc.sh
./benchmark-glacier.sh
./benchmark-arctic.sh
```

> **Known issue:** `hostname -I` is unsupported on ZimaOS Buildroot. The current scripts use `ip addr` instead. If you have an older copy, replace `hostname -I` with:
> ```bash
> ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1
> ```

---

## System Information

```
Model:     ZimaCube 2 (Standard)
OS:        ZimaOS (Buildroot-based, immutable)
Kernel:    Linux 6.17.13-3-pve
ZFS:       OpenZFS 2.3.2
fio:       3.38
btop:      ZimaOS App Marketplace
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
