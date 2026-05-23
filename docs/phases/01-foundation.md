# Phase 1 — Foundation: ZFS RAIDZ1, OCuLink & Core Services

**Status:** 🟡 In Progress  
**Started:** May 21, 2026  
**Updated:** May 23, 2026

---

## 🎯 Goal

Build a stable, tiered storage foundation with redundancy, snapshots, and core services. Document the real journey — including what went wrong.

---

## ✅ Completed

- [x] ZimaCube 2 Standard received and powered on
- [x] RAM upgraded: 8GB → 16GB DDR5 (Crucial 5600MHz CL46 SODIMM)
- [x] Crucial P510 2TB PCIe Gen5 installed in 7th Bay → Arctic-Storage (btrfs)
- [x] AppData + User Database migrated from ZimaOS-HD to Arctic-Storage via ZimaOS GUI migration tool
- [x] PCIe x4 → SFF-8612 OCuLink adapter installed in Slot 1
- [x] Aoostar TB4S-OC connected via OCuLink (TB4 abandoned — see below)
- [x] All 4× 2TB NVMe drives detected (nvme1n1–nvme4n1)
- [x] Glacier ZFS RAIDZ1 pool created at `/media/glacier`
- [x] 7 ZFS datasets created (VM, appdata, backup, documents, downloads, gallery, media)
- [x] ZimaOS symlinks created: `/DATA/glacier-*` → `/media/glacier/*`
- [x] Autotrim enabled on glacier pool
- [x] Netdata deployed (Docker) for real-time NVMe/ZFS monitoring
- [x] Full storage benchmarks completed (glacier vs Arctic-Storage)
- [x] Immich migrated from previous instance — 87,458 photos in glacier/gallery

## ⏳ Pending

- [ ] Nginx Proxy Manager — install and configure
- [ ] AdGuard Home — install and configure
- [ ] Beszel — install and configure
- [ ] RAM → 32GB DDR5 (2× Corsair Vengeance 16GB DDR5 4800MHz CL40 SODIMM)
- [ ] Move Crucial P510 to onboard M.2 slot → Phase 1.5 re-benchmark
- [ ] Phase 1 Dev.to post + Reddit cross-post

---

## 🛠️ Hardware Installed

### ZimaCube 2 Standard

| Component | Specification |
|---|---|
| Model | ZimaCube 2 Standard |
| CPU | Intel Core i3-1215U (12th Gen, 6-core) |
| RAM | 16GB DDR5 Crucial 5600MHz CL46 → upgrading to 2× 16GB Corsair Vengeance DDR5 4800MHz CL40 (32GB) |
| OS | ZimaOS (Buildroot-based, immutable, RAUC A/B OTA) |
| Network | 2× Intel i226 2.5GbE |
| Thunderbolt | 2× TB4 (both free — OCuLink occupies Slot 1) |
| PCIe Slot 1 | PCIe 4.0 x4 → OCuLink SFF-8612 adapter |
| PCIe Slot 2 | PCIe 3.0 x2 → available |
| 7th Bay | 4× M.2 NVMe (800 MB/s total — Standard model) |

### NVMe Drives

| Device | Model | Interface | Location | Role |
|---|---|---|---|---|
| nvme5n1 | Kingston OM8PGP4 256GB | PCIe Gen4 | Onboard M.2 | ZimaOS boot drive |
| nvme0n1 | Crucial P510 2TB (CT2000P510SSD8) | PCIe Gen5 | 7th Bay Slot 1 | Arctic-Storage (btrfs) |
| nvme1n1 | ORICO 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |
| nvme2n1 | ORICO 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |
| nvme3n1 | XPG GAMMIX S70 BLADE 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |
| nvme4n1 | XPG GAMMIX S70 BLADE 2TB | PCIe Gen4 | Aoostar TB4S-OC | Glacier RAIDZ1 |

---

## ⚠️ The TB4 Issue — What Actually Happened

### Original Plan
Connect the Aoostar TB4S-OC via Thunderbolt 4. This would leave Slot 1 free for Phase 4b GPU.

### What Failed

Despite proper external power, two certified TB4 cables, and both TB4 ports tested, the connection failed consistently:

```
thunderbolt: tb_path_activate+0x100/0x350 [thunderbolt]
thunderbolt 0000:00:0d.2: 0:8 <-> 1:3 (PCI): activation failed
thunderbolt 1-1: reading DROM failed: -107
thunderbolt 1-1: failed to initialize port 1
[endless retimer connect/disconnect loop]
```

### Root Causes Found

| Issue | Detail |
|---|---|
| `thunderbolt.host_reset=false` | ZimaOS boot parameter — TB controller won't reset on device plug-in |
| `security=user` on TB domains | Requires manual authorization; device never enumerated to authorize |
| `DROM failed: -107 (ENOTCONN)` | ASMedia ASM2462PDX inside Aoostar can't complete DROM handshake with ZimaCube 2 |
| TB port dead at boot | `0000:00:0d.3: 0:1: failed to reach state TB_PORT_UP. Ignoring port` |

### Resolution

Installed a **PCIe x4 → SFF-8612 OCuLink adapter** in Slot 1. All 4 drives detected on first boot. Zero configuration needed.

### Downstream Impact

With Slot 1 occupied:
- ~~Minisforum DEG1~~ (OCuLink-only) → ruled out
- Both TB4 ports are now free → evaluating **Minisforum DEG2** (TB5 + OCuLink) or a Aoostar TB4/TB5 eGPU dock for Phase 4b

**Community takeaway:** If connecting an Aoostar TB4S-OC to a ZimaCube 2, use OCuLink. TB4 has known issues with the ASM2462PDX chip on ZimaOS.

---

## 🗄️ ZFS Glacier Pool Setup

### Why ZFS RAIDZ1

- Checksums detect and self-heal silent data corruption — critical for long-term photo/document storage
- Survives 1 drive failure across 4 drives
- Copy-on-write snapshots are instant — invaluable before Phase 4 experiments
- lz4 compression is near-zero CPU cost; real savings on documents and logs
- btrfs chosen for Arctic-Storage (single drive) purely for ZimaOS native UI recognition

### Pool Creation

```bash
sudo -i

# Wipe drives first (already done in Proxmox before migration)
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

### ZimaOS Integration via Symlinks

ZimaOS (Buildroot-based, no apt) is immutable — ZFS pools created via CLI are invisible to the storage UI. Workaround: symlinks in `/DATA` make datasets appear in the Files app.

```bash
ln -s /media/glacier/VM        /DATA/glacier-VM
ln -s /media/glacier/appdata   /DATA/glacier-AppData
ln -s /media/glacier/backup    /DATA/glacier-Backup
ln -s /media/glacier/documents /DATA/glacier-Documents
ln -s /media/glacier/downloads /DATA/glacier-Downloads
ln -s /media/glacier/gallery   /DATA/glacier-Gallery
ln -s /media/glacier/media     /DATA/glacier-Media
```

### Pool Health Check

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

## 🌨️ Arctic-Storage Setup

The Crucial P510 2TB PCIe Gen5 was installed in the 7th Bay and formatted via the ZimaOS GUI — ZimaOS automatically formatted it as **btrfs** and named it Arctic-Storage. This gives it native ZimaOS UI recognition (storage dashboard, Apps migration tool) that a CLI-created ZFS volume cannot have.

AppData was migrated from ZimaOS-HD to Arctic-Storage using **Settings → Storage → Apps** — ZimaOS created symlinks automatically.

> ⚠️ **7th Bay bandwidth cap:** ZimaCube 2 Standard caps the 7th Bay at 800 MB/s total via its ASMedia bridge. The P510 is capable of 9,000+ MB/s natively but is bridge-limited here. See benchmark results below.

> 🔬 **Planned — Phase 1.5:** Move P510 to the additional onboard M.2 slot to test native PCIe Gen5 speed. Re-benchmark and compare.

---

## 📊 Benchmarks (May 23, 2026)

Tool: `fio 3.38` (native on ZimaOS). Monitored via Netdata (Docker). Scripts in `scripts/` folder.

### Results

| Test | Glacier ZFS RAIDZ1 | Arctic btrfs PCIe 5.0 |
|---|---|---|
| Sequential write | **1,726 MB/s** (1,646 IOPS) | 788 MB/s (751 IOPS) |
| Sequential read | **2,591 MB/s** (2,470 IOPS) | 874 MB/s (833 IOPS) |
| Random 4K write | 56.5 MB/s (**13,795 IOPS** · 9.3ms) | 357 MB/s (**87,099 IOPS** · 1.5ms) |
| Random 4K read | 60.5 MB/s (**14,781 IOPS** · 8.7ms) | 842 MB/s (**205,588 IOPS** · 0.6ms) |

### Key Takeaways

- **Glacier sequential read (2,591 MB/s)** approaches the theoretical 3,200 MB/s OCuLink ceiling — near-perfect RAIDZ1 stripe distribution
- **Arctic random 4K read (205,588 IOPS · 0.6ms)** is genuine PCIe Gen5 NVMe performance, completely unaffected by the 7th Bay sequential cap
- The 14× IOPS gap is architectural — ZFS RAIDZ1 trades random I/O for sequential throughput and redundancy
- Glacier random IOPS will improve over time as ZFS ARC warms with frequently accessed data

### Workload Split (based on results)

| Workload | Storage | Reason |
|---|---|---|
| Immich gallery (87K photos) | Glacier | Large sequential reads, redundancy, 5.5TB capacity |
| Docker AppData | Arctic-Storage | Low latency random I/O, native ZimaOS recognition |
| VM images | Glacier | Sequential, RAIDZ1 redundancy |
| Ollama models (Phase 4a) | Arctic-Storage | Low latency random reads for inference |
| Bulk media (arriving) | sata-hdd | Capacity, cost-per-TB |

---

## 📸 Immich Migration (Phase 2.5 — In Progress)

Phase 2 (media stack with SATA drives) is on hold pending hardware arrival. In the meantime, Immich is being set up using glacier as the photo library.

### Migration Status

- Source: Previous ZimaOS instance at 192.168.50.102
- 87,458 photos + videos, ~169GB
- Library migrated to `/media/Arctic-Storage/Gallery/immich` → symlinked as `/DATA/Gallery`
- Immich compose volume updated to point at new path
- Database restore from source instance in progress

### Immich Architecture on ZimaCube 2

| Container | Version | Data Path |
|---|---|---|
| immich-server | v2.1.0 | `/DATA/Gallery/immich` → `/media/Arctic-Storage/Gallery/immich` |
| immich-postgres | 14-vectorchord0.4.3 | `/DATA/AppData/immich/pgdata` |
| immich-machine-learning | v2.1.0 | `/DATA/AppData/immich/model-cache` |
| immich-redis (valkey) | 9 | In-memory only |

> 📝 **Note:** Database restore from source instance is the correct approach to recover albums, faces, and metadata. A fresh install + external library scan only recovers photos, not Immich metadata.

---

## 🗒️ ZimaOS Observations

ZimaOS is **Buildroot-based** with an immutable read-only OS. Key implications:

| Fact | Impact |
|---|---|
| No apt/yum/package manager | All extra software runs as Docker containers or is available natively |
| `fio`, `zpool`, `zfs`, `nvme`, `iostat` available natively | Benchmarking works out of the box |
| ZFS pools created via CLI are invisible to UI | Use symlinks in `/DATA` to expose datasets in Files app |
| `thunderbolt.host_reset=false` in kernel boot | TB devices don't re-enumerate on plug-in |
| RAUC A/B OTA updates | Kernel updates safe — but verify ZFS DKMS survives each update |
| AppData migration tool in Settings → Storage → Apps | Moves AppData/Docker images to any ZimaOS-recognised drive |

---

## 📝 Honest Friction Log

- **TB4 failure** — biggest surprise. ZimaOS TB4 kernel config + ASMedia chip incompatibility = hours of troubleshooting. OCuLink was the right answer all along.
- **ZFS invisible to ZimaOS UI** — expected but still a rough edge. Symlink workaround works but isn't elegant. Feature request open on ZimaOS GitHub.
- **Immich database empty after file migration** — moving files doesn't move the database. Full pg_dump/restore from source instance required to recover albums and face tags.
- **ZimaOS package manager missing** — `apt install fio` doesn't work. Discovered fio was already available natively, but anything else requires Docker.
- **hostname -I not supported** — Buildroot's hostname binary doesn't support `-I` flag. Use `ip addr` instead in scripts.
