# Phase 1 — Foundation: ZFS RAIDZ1 & Core Services

## 🎯 Goal
Build a stable storage foundation with redundancy, snapshots, and core services on the ZimaCube *2*.

---

## 🛠️ Hardware Checklist (Day 1)
- [ ] Maintain stock 8GB → **hold off upgrade of 2 x 16GB DDR5 kit until Day 7**
- [ ] Install **4× 2TB NVMe** using Thunderbolt 4 enclosure (Aoostar tbs4s-oc https://nascompares.com/2024/10/09/aoostar-tb4s-oc-review/)
- [ ] Plug into 2.5GBps managed switch
- [ ] Connect external display ARZOPA 16.1" 180Hz Portable Gaming Monitor - Z3FC (https://www.arzopa.com/products/arzopa-z3fc-16-1-180hz-2560x1440-qhd-portable-gaming-monitor)
- [ ] Connect low-profile mechanical keyboard 96% layout / 100 keys (https://www.lofree.co/products/flow-lite100-mechanical-keyboard) 


---

## 📦 What We're Building This Phase
| Service | Purpose | Container/Tool |
|----------|----------|-----------------|
| ZFS Pool | Storage with RAIDZ1 | Native (no container) |
| AdGuard Home | Network DNS + ad blocking | Docker |
| Caddy | Reverse proxy for all services | Docker |
| Besfel | Monitoring dashboard | Docker |

---

 

## 📝 My Notes & Observations
(Write down what you observe during setup — errors, surprises, things that worked better than expected)

---

## ✅ Verification Checklist (to complete later)
- [ ] ZFS pool healthy with RAIDZ1
- [ ] Snapshots running every hour
- [ ] AdGuard Home accessible at the right port
- [ ] Caddy routing to all services correctly
