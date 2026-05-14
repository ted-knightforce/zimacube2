# Phase 1 — Foundation: ZFS RAIDZ1 & Core Services

## 🎯 Goal
Build a stable storage foundation with redundancy, snapshots, and core services on the ZimaCube *2*.

---

## 🛠️ Hardware Checklist (Day 1)
- [ ] Maintain stock 8GB → **hold off upgrade of 2 x 16GB DDR5 kit until Day 7**
- [ ] Install **4× 2TB NVMe** using Thunderbolt 4 enclosure (Aoostar tbs4s-oc) https://nascompares.com/2024/10/09/aoostar-tb4s-oc-review/
- [ ] Plug into 2.5GBps managed switch
- [ ] Connect external display ARZOPA 16.1" 180Hz Portable Gaming Monitor - Z3FC https://www.arzopa.com/products/arzopa-z3fc-16-1-180hz-2560x1440-qhd-portable-gaming-monitor
- [ ] Connect low-profile mechanical keyboard 96% layout / 100 keys https://www.lofree.co/products/flow-lite100-mechanical-keyboard


---

## 📦 What We're Building This Phase
| Service | Purpose | Container/Tool |
|----------|----------|-----------------|
| ZFS Pool | Storage with RAIDZ1 | Native (no container) |
| AdGuard Home | Network DNS + ad blocking | ZimaOS App Store |
| Nginx Proxy Manager | Reverse proxy for all services | ZimaOS App Store |
| Beszel | Monitoring dashboard | ZimaOS App Store |

---

 

## 📝 My Notes & Observations
ZimaOS is built on top of CasaOS/Debian under the hood (or at least that's what I believed), so it uses BTRFS as its native filesystem for most things. It does not come with a pre-configured ZFS pool out of the box.

The Reality Check (What You Can Actually Do)
Phase 1 (ZFS): I'll need to manually create the ZFS pool via CLI since ZimaOS won't do it automatically. This requires SSH-ing into my ZimaCube 2 and running the zpool create commands. IF it works, it's not a one-click thing.

Phase 1 (BTRFS): If I decide to stick with what ships out of the box, BTRFS is fine for most home storage needs — just less advanced than ZFS - found in TrueNAS and Proxmox.


---

## ✅ Verification Checklist (to complete later)
- [ ] ZFS pool healthy with RAIDZ1
- [ ] BTRFS pool healthy with RAID5 (contigency)
- [ ] Snapshots running 24 hours (if successfully setup ZFS )
- [ ] AdGuard Home accessible at the right port
- [ ] Caddy routing to all services correctly
