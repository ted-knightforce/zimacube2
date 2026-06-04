# Phase 4a — CPU-Only Local AI Baseline

**Status:** ⏳ Planned — after Phase 1 complete and RAM upgraded to 32GB  
**Prerequisite:** 2× Corsair Vengeance 16GB DDR5 4800MHz installed

---

## 🎯 Goal

Establish a CPU-only inference baseline on the i3-1215U before the GPU arrives. Document honest real-world performance — tokens/sec, time-to-first-token, RAM usage — as a reference point for Phase 4b GPU comparison.

---

## 🛠️ Hardware at This Phase

| Component | Specification |
|---|---|
| CPU | Intel Core i3-1215U (6-core, 12th Gen) |
| RAM | 32GB DDR5 4800MHz (Corsair Vengeance 2× 16GB; board supports up to 64GB) |
| Model storage | Arctic-Storage (`/media/Arctic-Storage/AppData/ollama`) |
| RAM for cache | ~20GB+ free for the Linux page cache and model residency at 32GB RAM |

> **Why Arctic-Storage for models?** Random 4K read at 0.6ms latency vs glacier's 8.7ms — a raw NVMe advantage, faster model loading = better time-to-first-token.
>
> **Note on caching:** Arctic-Storage is **btrfs**, so it is **not** served by the ZFS ARC (ARC caches glacier reads only). btrfs reads are absorbed by the Linux page cache, and once Ollama loads a model it stays resident in RAM, so storage latency mainly affects the first load and model switches.

---

## 📦 Stack

| Service | Purpose | Install Method |
|---|---|---|
| Ollama | LLM inference engine | ZimaOS App Store |
| Open WebUI | Chat interface | ZimaOS App Store |

---

## 🧪 Benchmark Models

| Model | Size | RAM Required | Expected CPU Performance |
|---|---|---|---|
| llama3.2:3b | ~2GB | ~4GB | Usable — fast enough for daily tasks |
| llama3.1:8b | ~5GB | ~8GB | Moderate — reasonable for light use |
| qwen2.5:7b | ~5GB | ~8GB | Good instruction following |
| llama3.1:8b-q4 | ~4.5GB | ~7GB | Quantized — better CPU speed |

---

## 📊 Metrics to Capture

For each model:
- Tokens/second (generation speed)
- Time to first token (TTFT)
- RAM usage (peak)
- CPU utilisation (%)
- Model load time — cold (first read from Arctic-Storage) vs warm (already resident in RAM)

Capture via Netdata dashboard during inference. For model-load I/O, watch the Arctic-Storage NVMe with `iostat -x 1` (ZFS `arcstats`/`zpool iostat` are not relevant here — models live on btrfs, not glacier).

---

## 🔧 Ollama Setup

```bash
# Ollama model storage on Arctic-Storage (low latency)
# Set via ZimaOS App Store Ollama settings → volume mount:
# /media/Arctic-Storage/AppData/ollama → /root/.ollama

# Pull baseline models
ollama pull llama3.2:3b
ollama pull llama3.1:8b
ollama pull qwen2.5:7b

# Test inference
ollama run llama3.2:3b "Explain ZFS RAIDZ1 in simple terms"
```

---

## 📝 Post Title

"Local AI on a $799 NAS Before I Add a GPU — Honest CPU-Only Benchmarks (i3-1215U)"

Cross-post: r/LocalLLaMA + r/selfhosted + r/ZimaCube
