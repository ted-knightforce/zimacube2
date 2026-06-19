# Phase 3 — Data Management: Backup, Nextcloud & 3-2-1 Strategy

**Status:** ⏳ Planned — after Phase 2 SATA pool complete

---

## 🎯 Goal

I will never forgive myself if I can't recover these photos and videos. They're priceless — years of family memories that no amount of money or hardware could ever replace. Phase 3 is about making absolutely sure that never happens. The plan is a classic 3-2-1: three copies of everything that matters, across two different types of storage, with one copy kept offsite. Straightforward to describe, a bit of work to actually build — but non-negotiable.

---

## 📦 What I'm Setting Up

| Service | Purpose | Install Method |
|---|---|---|
| ZFS Snapshots | Automated local point-in-time recovery | CLI (cron) |
| Kopia | Backup to external drive + Backblaze B2 | ZimaOS App Store / Docker |
| Nextcloud (optional) | Personal cloud — files, calendar, contacts | ZimaOS App Store |
| ZimaOS Backup | Native ZimaOS backup tool | Built-in |

---

## 💾 The 3-2-1 Plan

```
3 copies of data
  ├── Copy 1: live data — glacier (ZFS RAIDZ1) + Arctic-Storage (btrfs, Immich + AppData)
  ├── Copy 2: On-site backup → external USB drive or ironwolf
  └── Copy 3: Offsite → Backblaze B2 (~AU$2–5/month for 200–500GB)

2 different storage media
  ├── NVMe RAIDZ1 (primary)
  └── HDD or cloud (secondary)

1 offsite copy
  └── Backblaze B2 via Kopia
```

---

## ⏱️ ZFS Snapshot Schedule

```bash
# Daily snapshot — glacier pool
echo "0 2 * * * root zfs snapshot -r glacier@daily-\$(date +%Y%m%d)" >> /etc/crontab

# Monthly scrub for data integrity (1st of month, 03:00)
echo "0 3 1 * * root zpool scrub glacier" >> /etc/crontab

# Key manual snapshots before major changes
zfs snapshot -r glacier@pre-phase-4a       # Before Ollama install
zfs snapshot -r glacier@pre-nvidia         # Before NVIDIA drivers
zfs snapshot -r glacier@pre-p510-move      # Before moving P510 to onboard slot
```

---

## 🗒️ What Gets Backed Up — and What Doesn't

Not everything deserves a backup. Movies and TV shows are re-downloadable — wasting offsite bandwidth on them makes no sense. Ollama models are the same story. What's genuinely irreplaceable gets backed up. Everything else doesn't.

**Include:**
- `glacier/documents` — personal documents
- `/DATA/Gallery/immich` (`Arctic-Storage`) — Immich photo library (irreplaceable)
- `glacier/backup` — already a backup destination, but also back up metadata
- `Arctic-Storage/AppData` — Docker app configs and databases

**Exclude:**
- `glacier/media` — re-downloadable media
- `ironwolf/media` — re-downloadable
- `ironwolf/downloads` — transient
- `Arctic-Storage/AppData/ollama` — AI models are re-downloadable

---

## 📝 Post Title (Planned)

"A Reliable 24×7 Data Layer on ZimaOS — Native First, Extend Where Needed"

Cross-post: r/selfhosted + r/ZimaCube + r/DataHoarder
