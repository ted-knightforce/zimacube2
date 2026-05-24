# Phase 2 — Media Stack: Jellyfin, *arr, SATA Pool

**Status:** ⏸️ On Hold — SATA drives arriving  
**Blocker:** 3× Seagate IronWolf 4TB drives not yet received

---

## 🎯 Goal

Build a complete media server with hardware-accelerated transcoding, automated library management, and a ZFS RAIDZ1 cold storage pool for bulk media.

---

## ⏸️ Why On Hold

The original Phase 2 plan requires the **3× Seagate IronWolf 4TB SATA drives** to create the cold storage pool for bulk media (movies, TV shows, music). These drives are in transit.

While waiting, **Phase 2.5 (Immich)** is being executed instead — migrating the existing photo library to ZimaCube 2 using `Arctic-Storage` (P510 NVMe) at the standard ZimaOS paths `/DATA/AppData/immich` and `/DATA/Gallery/immich`. Immich setup is documented in [Phase 2.5 — Immich](02.5-immich.md).

> **Note:** The README originally listed "BTRFS RAID5" for SATA drives. This has been corrected to **ZFS RAIDZ1** — consistent with the rest of the build. btrfs RAID5/6 has known reliability issues and is not recommended for production data.

---

## 🛠️ Hardware Required

| Item | Specification | Status |
|---|---|---|
| Seagate IronWolf × 3 | 4TB, 3.5", SATA 6Gb/s, 5,400 RPM, CMR, 256MB cache | 🚚 In transit |

---

## 📦 What We're Building This Phase

| Service | Purpose | Install Method |
|---|---|---|
| ZFS sata-hdd pool | RAIDZ1 cold storage ~8TB usable | CLI (SSH) |
| Jellyfin | Media server + Intel QuickSync transcoding | ZimaOS App Store |
| Sonarr | TV show automation | ZimaOS App Store |
| Radarr | Movie automation | ZimaOS App Store |
| Prowlarr | Indexer manager | ZimaOS App Store |
| qBittorrent | Download client | ZimaOS App Store |
| Jellyseerr | Request management | ZimaOS App Store |
| Gluetun | VPN container for downloads | Docker Compose |

---

## 🗄️ SATA Pool Setup (When Drives Arrive)

```bash
sudo -i

# Identify IronWolf drives
lsblk
ls -la /dev/disk/by-id/ | grep ata

# Create ZFS RAIDZ1 pool
zpool create -f \
  -m /media/sata-hdd \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  sata-hdd raidz1 \
  /dev/disk/by-id/ata-<DRIVE1> \
  /dev/disk/by-id/ata-<DRIVE2> \
  /dev/disk/by-id/ata-<DRIVE3>

# Create datasets
zfs create sata-hdd/media
zfs create sata-hdd/media/movies
zfs create sata-hdd/media/tv
zfs create sata-hdd/media/music
zfs create sata-hdd/downloads
zfs create sata-hdd/photos

# Expose via symlinks
ln -s /media/sata-hdd/media   /DATA/sata-Media
ln -s /media/sata-hdd/downloads /DATA/sata-Downloads
ln -s /media/sata-hdd/photos  /DATA/sata-Photos
```

---

## 📂 Storage Layout (Post-Phase 2)

| Content | Pool | Path |
|---|---|---|
| Movies | `sata-hdd` | `/media/sata-hdd/media/movies` |
| TV Shows | `sata-hdd` | `/media/sata-hdd/media/tv` |
| Music | `sata-hdd` | `/media/sata-hdd/media/music` |
| Downloads (transient) | `sata-hdd` | `/media/sata-hdd/downloads` |
| Photos archive (bulk) | `sata-hdd` | `/media/sata-hdd/photos` |
| Immich photo library | `Arctic-Storage` | `/DATA/Gallery/immich` |
| Jellyfin appdata | `Arctic-Storage` | `/media/Arctic-Storage/AppData/jellyfin` |

---

## 🔧 Jellyfin Hardware Transcoding

ZimaCube 2 Standard's i3-1215U includes Intel QuickSync. Jellyfin config needed:

```yaml
# Add to Jellyfin docker compose
devices:
  - /dev/dri:/dev/dri
environment:
  - JELLYFIN_PublishedServerUrl=http://192.168.50.206
```

Enable hardware acceleration in Jellyfin UI: Dashboard → Playback → Hardware Acceleration → Intel QuickSync Video.

---

## 📝 Post Title (Planned)

"*arr Stack on ZimaOS — App Store First, Compose Where Needed"

Cross-post: r/selfhosted + r/ZimaCube
