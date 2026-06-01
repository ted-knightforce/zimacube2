# Phase 2 — Media Stack: Jellyfin, *arr, IronWolf Pool

**Status:** ⏸️ On Hold — SATA drives arriving  
**Blocker:** 4× Seagate IronWolf 4TB drives not yet fully received (1 of 4 in hand, 3 in transit)

---

## 🎯 Goal

Build a complete media server with hardware-accelerated transcoding, automated library management, and a ZFS RAIDZ1 cold storage pool for bulk media.

---

## ⏸️ Why On Hold

Phase 2 requires all **4× Seagate IronWolf 4TB SATA drives** to create the `ironwolf` btrfs RAID5 pool for bulk media. 1 drive has been received; the remaining 3 are in transit (originally ordered 3, a 4th was added to the order for a total of 4).

> **Pool architecture summary:**
> | Pool | Filesystem | Config | Managed by |
> |---|---|---|---|
> | `glacier` | ZFS | RAIDZ1 — 4× 2TB NVMe | CLI (SSH) |
> | `Arctic-Storage` | btrfs | Single drive — 1× 2TB NVMe | ZimaOS Storage Manager |
> | `ironwolf` | btrfs | RAID5 — 4× 4TB SATA HDD | ZimaOS Storage Manager |

While waiting, **Phase 2.5 (Immich)** has been executed instead — migrating the existing photo library to ZimaCube 2 using `Arctic-Storage` (P510 NVMe) at the standard ZimaOS paths `/DATA/AppData/immich` and `/DATA/Gallery/immich`. Immich setup is documented in [Phase 2.5 — Immich](02.5-immich.md).

---

## 🛠️ Hardware Required

| Item | Specification | Status |
|---|---|---|
| Seagate IronWolf 4TB × 1 | 4TB, 3.5", SATA 6Gb/s, 5,400 RPM, CMR, 256MB cache | ✅ In hand |
| Seagate IronWolf 4TB × 3 | 4TB, 3.5", SATA 6Gb/s, 5,400 RPM, CMR, 256MB cache | 🚚 In transit |

---

## 📦 What We're Building This Phase

| Service | Purpose | Install Method |
|---|---|---|
| btrfs ironwolf pool | RAID5 ~12TB usable (4× 4TB, 3 data + 1 parity) | ZimaOS Storage Manager |
| Jellyfin | Media server + Intel QuickSync transcoding | ZimaOS App Store |
| Sonarr | TV show automation | ZimaOS App Store |
| Radarr | Movie automation | ZimaOS App Store |
| Prowlarr | Indexer manager | ZimaOS App Store |
| qBittorrent | Download client | ZimaOS App Store |
| Jellyseerr | Request management | ZimaOS App Store |
| Gluetun | VPN container for downloads | Docker Compose |

---

## 🗄️ IronWolf Pool Setup (When All Drives Arrive)

The `ironwolf` pool is created through **ZimaOS Storage Manager** — the same way Arctic-Storage was set up. ZimaOS handles the btrfs formatting, RAID5 assembly, and native UI integration automatically.

### Step 1 — Create the RAID5 pool via ZimaOS Storage Manager

1. Install all 4× IronWolf drives into ZimaCube 2's SATA bays
2. Open **ZimaOS → Storage Manager**
3. The 4 new drives will appear as unformatted disks
4. Select all 4 drives → choose **RAID5** → name the pool `ironwolf`
5. ZimaOS formats as btrfs RAID5 and mounts the pool automatically

**Result:** ~12TB usable (4× 4TB, 3 data + 1 parity). Pool appears in ZimaOS UI and is accessible at its mount path.

### Step 2 — Create folder structure and symlinks (SSH)

Once the pool is mounted, create the media folder structure and expose it via `/DATA` symlinks so ZimaOS apps can see it:

```bash
sudo -i

# Verify the pool is mounted (path will be ZimaOS-assigned — confirm in Storage Manager UI)
df -h | grep ironwolf

# Create folder structure
mkdir -p /media/ironwolf/media/movies
mkdir -p /media/ironwolf/media/tv
mkdir -p /media/ironwolf/media/music
mkdir -p /media/ironwolf/downloads
mkdir -p /media/ironwolf/photos

# Expose via symlinks so ZimaOS apps can reference /DATA paths
ln -s /media/ironwolf/media     /DATA/ironwolf-Media
ln -s /media/ironwolf/downloads /DATA/ironwolf-Downloads
ln -s /media/ironwolf/photos    /DATA/ironwolf-Photos
```

---

## 📂 Storage Layout (Post-Phase 2)

| Content | Pool | Path |
|---|---|---|
| Movies | `ironwolf` | `/media/ironwolf/media/movies` |
| TV Shows | `ironwolf` | `/media/ironwolf/media/tv` |
| Music | `ironwolf` | `/media/ironwolf/media/music` |
| Downloads (transient) | `ironwolf` | `/media/ironwolf/downloads` |
| Photos archive (bulk) | `ironwolf` | `/media/ironwolf/photos` |
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
