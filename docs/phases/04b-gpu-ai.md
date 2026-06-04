# Phase 4b — GPU Integration: RTX 4090 + eGPU Dock

**Status:** ⏳ Planned — eGPU dock decision pending  
**Prerequisite:** Phase 4a complete · eGPU dock selected and purchased

---

## 🎯 Goal

Add an RTX 4090 to ZimaCube 2, install NVIDIA drivers on ZimaOS, and benchmark GPU-accelerated Ollama inference against the Phase 4a CPU baseline. The 24GB VRAM unlocks large models impossible to run on CPU alone.

---

## ⚠️ eGPU Dock Decision — Pending

The original plan (Minisforum DEG1, OCuLink) is **no longer viable** because PCIe Slot 1 is occupied by the OCuLink adapter for the Aoostar TB4S-OC NVMe enclosure.

### Decision Matrix

| Option | Connection | Pros | Cons | Status |
|---|---|---|---|---|
| Minisforum DEG1 | OCuLink → Slot 1 | Hosts a full-size GPU (e.g. RTX 4090) on ZimaCube 2 via OCuLink — direct PCIe with no Thunderbolt protocol/tunnelling overhead, and sidesteps the TB4/TB5 eGPU hardware-compatibility issues seen with my Aoostar TB4S-OC TB4 DAS | ❌ Cannot use the Slot 1 OCuLink connection — it's already taken by the Aoostar TB4S-OC NVMe SSD enclosure hosting the ultra-fast NVMe ZFS RAIDZ1 `glacier` pool | Ruled out |
| **Minisforum DEG2 · Aoostar EG02 / EG03** | **TB4** | Uses a free TB4 port; keeps the PCIe slots free | ZimaCube 2 has only TB4 ports → bandwidth capped at TB4 (~40 Gbps); Thunderbolt protocol/tunnelling overhead | **Top choice — under evaluation** |

> **Key insight:** For Ollama inference workloads, TB4 bandwidth (~40Gbps ≈ 5 GB/s) is not the bottleneck. PCIe x16 full bandwidth matters for gaming (Phase 6) but inference is VRAM-bound, not bandwidth-bound. TB4 eGPU is a valid path for Phase 4b.

---

## 🛠️ Hardware Required

| Item | Specification | Notes |
|---|---|---|
| RTX 4090 24GB | Used market | ~AU$1,800–2,500 · Best VRAM/$ for LLM |
| eGPU dock (TBD) | Minisforum DEG2, Aoostar EG02/EG03, or TB4 enclosure | Decision pending |
| Power supply (for the dock) | SFX or ATX, 700W minimum · 850W recommended | The eGPU dock needs its own PSU — most docks ship without one. RTX 4090 board power ≈ 450W plus transient spikes, so 700W+ is the floor; 850W is the safe bet. Using an **EVGA SuperNOVA 850W ATX** |

---

## 📦 Stack

| Service | Purpose |
|---|---|
| NVIDIA drivers | Host-level GPU access on ZimaOS |
| NVIDIA Container Toolkit | GPU access inside Docker containers |
| Ollama (GPU mode) | GPU-accelerated inference |
| Open WebUI | Chat interface (same as Phase 4a) |

---

## 🧪 Benchmark Plan

Run identical model/prompt set from Phase 4a. Compare directly:

| Metric | Phase 4a (CPU) | Phase 4b (RTX 4090) | Expected delta |
|---|---|---|---|
| llama3.1:8b tokens/sec | baseline | target | 20–50× faster |
| Time to first token | baseline | target | Much lower |
| Largest runnable model | ~8B (32GB RAM) | ~32–34B at Q4 fully on GPU · 70B with GPU+CPU offload (24GB VRAM) | Major jump |
| Power consumption (whole system) | ~45–65W under inference (idle ~20–30W) | ~400–550W peak | Significant |

---

## 🔧 NVIDIA on ZimaOS

> ⚠️ ZimaOS uses RAUC A/B kernel updates. Pin the kernel version after NVIDIA driver install. DKMS modules must survive each ZimaOS update — verify after every update.

```bash
# Take snapshot before NVIDIA install
zfs snapshot -r glacier@pre-nvidia

# NVIDIA driver install — method TBD based on ZimaOS version at time of Phase 4b
# Check ZimaOS community forum for current recommended approach
```

---

## 📊 Monitoring

GPU metrics via Netdata during inference:
- GPU utilisation %
- VRAM used / free
- GPU temperature
- Power consumption

---

## 📝 Post Title

"Adding an RTX 4090 to ZimaCube 2 via [TB4/OCuLink] — What 24GB of VRAM Actually Buys You"

Cross-post: r/LocalLLaMA + r/eGPU + r/ZimaCube + r/selfhosted
