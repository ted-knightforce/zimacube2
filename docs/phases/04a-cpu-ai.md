# Phase 4a — Running Local AI on a NAS Before the GPU Arrives

**Status:** ⏳ Planned — after Phase 1 complete and RAM upgraded to 32GB  
**Prerequisite:** 2× Corsair Vengeance 16GB DDR5 4800MHz installed

---

## 🎯 Goal

The RTX 4090 isn't here yet — so why not find out how far an i3-1215U can actually take you with local LLMs? Instead of waiting for the GPU, I wanted honest numbers first: not "it works" but actual tokens per second, actual time to first response, actual RAM usage under load. Phase 4b will run the exact same tests once the GPU arrives. Then we'll see what 24GB of VRAM actually buys you.

---

## 🛠️ Hardware at This Phase

The 32GB RAM upgrade is the prerequisite here — not because the CPU needs it for inference, but because ZFS ARC and Docker workloads eat into headroom quickly. With 32GB, Ollama isn't competing with the rest of the system for memory.

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

I picked these four to cover a range of sizes and quantisation levels. The 3B model is the sanity check — if even that's sluggish on the i3, the CPU path isn't viable for daily use. The 8B models are where it gets interesting, since that's the size most people actually want to run.

| Model | Size | RAM Required | Expected CPU Performance |
|---|---|---|---|
| llama3.2:3b | ~2GB | ~4GB | Usable — fast enough for daily tasks |
| llama3.1:8b | ~5GB | ~8GB | Moderate — reasonable for light use |
| qwen2.5:7b | ~5GB | ~8GB | Good instruction following |
| llama3.1:8b-q4 | ~4.5GB | ~7GB | Quantized — better CPU speed |

---

## 📊 What I'm Measuring — and Why

Tokens per second is the headline number but it doesn't tell the whole story. Time to first token matters a lot for how a model *feels* to use — a model that starts responding in two seconds feels snappy even if generation is slower. Model load time separates "first run of the day" from "already warm in RAM" performance. Both matter.

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
