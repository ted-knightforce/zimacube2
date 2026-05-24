# Phase 3 — Data Management: Backup, Nextcloud & 3-2-1 Strategy

**Status:** ⏳ Planned — after Phase 2 SATA pool complete

---

## 🎯 Goal

Unified data protection with a proper 3-2-1 backup strategy: local ZFS snapshots, on-site backup to external drive, and offsite backup to Backblaze B2.

---

## 📦 What We're Building

| Service | Purpose | Install Method |
|---|---|---|
| ZFS Snapshots | Automated local point-in-time recovery | CLI (cron) |
| Kopia | Backup to external drive + Backblaze B2 | ZimaOS App Store / Docker |
| Nextcloud (optional) | Personal cloud — files, calendar, contacts | ZimaOS App Store |
| ZimaOS Backup | Native ZimaOS backup tool | Built-in |

---

## 💾 3-2-1 Backup Strategy

```
3 copies of data
  ├── Copy 1: glacier ZFS RAIDZ1 (primary)
  ├── Copy 2: On-site backup → external USB drive or sata-hdd
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

# Weekly scrub for data integrity
echo "0 3 1 * * root zpool scrub glacier" >> /etc/crontab

# Key manual snapshots before major changes
zfs snapshot -r glacier@pre-phase-4a       # Before Ollama install
zfs snapshot -r glacier@pre-nvidia         # Before NVIDIA drivers
zfs snapshot -r glacier@pre-p510-move      # Before moving P510 to onboard slot
```

---

## 🗒️ What to Back Up

**Include:**
- `glacier/documents` — personal documents
- `/DATA/Gallery/immich` (`Arctic-Storage`) — Immich photo library (irreplaceable)
- `glacier/backup` — already a backup destination, but also back up metadata
- `Arctic-Storage/AppData` — Docker app configs and databases

**Exclude:**
- `glacier/media` — re-downloadable media
- `sata-hdd/media` — re-downloadable
- `sata-hdd/downloads` — transient
- `Arctic-Storage/AppData/ollama` — AI models are re-downloadable

---

## 📝 Post Title (Planned)

"A Reliable 24×7 Data Layer on ZimaOS — Native First, Extend Where Needed"

Cross-post: r/selfhosted + r/ZimaCube + r/DataHoarder
