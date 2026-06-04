#!/bin/bash
# ============================================================
# ZimaCube 2 Pioneer Build — Benchmark Script
# Target: Arctic-Storage btrfs PCIe 5.0 (7th Bay)
# Drive: 1x Crucial P510 2TB PCIe 5.0 NVMe
# ============================================================

POOL="/media/Arctic-Storage"
TESTFILE="$POOL/fio-benchmark.tmp"
RESULTS="$POOL/benchmark-results-arctic.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colours
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
echo "============================================================"
echo "  ZimaCube 2 Pioneer Build — Arctic-Storage btrfs Benchmark"
echo "  7th Bay — Crucial P510 2TB PCIe 5.0 NVMe"
echo "  Started: $TIMESTAMP"
echo "============================================================"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}⚠️  Please run as root: sudo -i then ./benchmark-arctic.sh${NC}"
  exit 1
fi

# Check if fio is available
if ! command -v fio &> /dev/null; then
  echo -e "${YELLOW}⚠️  fio not found. Install via Docker or check ZimaOS tools.${NC}"
  exit 1
fi

# Check if pool is mounted
if [ ! -d "$POOL" ]; then
  echo -e "${YELLOW}⚠️  Arctic-Storage not found at $POOL${NC}"
  exit 1
fi

# Write results header
echo "============================================================" > $RESULTS
echo "  Arctic-Storage btrfs PCIe 5.0 Benchmark Results" >> $RESULTS
echo "  Date: $TIMESTAMP" >> $RESULTS
echo "  Pool: $POOL" >> $RESULTS
echo "============================================================" >> $RESULTS

# ------------------------------------------------------------
echo -e "${GREEN}[1/4] Sequential Write Test (Large files — media/backup)${NC}"
echo "" >> $RESULTS
echo "--- Sequential Write (1M blocks, 4 jobs) ---" >> $RESULTS

fio --name=arctic-seq-write \
  --filename=$TESTFILE \
  --rw=write \
  --bs=1M \
  --size=8G \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --direct=1 \
  --ioengine=libaio \
  --iodepth=8 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

# ------------------------------------------------------------
echo -e "${GREEN}[2/4] Sequential Read Test (Large files — media/backup)${NC}"
echo "" >> $RESULTS
echo "--- Sequential Read (1M blocks, 4 jobs) ---" >> $RESULTS

fio --name=arctic-seq-read \
  --filename=$TESTFILE \
  --rw=read \
  --bs=1M \
  --size=8G \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --direct=1 \
  --ioengine=libaio \
  --iodepth=8 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

# ------------------------------------------------------------
echo -e "${GREEN}[3/4] Random 4K Write Test (Docker/AI/database workload)${NC}"
echo "" >> $RESULTS
echo "--- Random 4K Write (IOPS test, 4 jobs) ---" >> $RESULTS

fio --name=arctic-rand-write \
  --filename=$TESTFILE \
  --rw=randwrite \
  --bs=4k \
  --size=4G \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --direct=1 \
  --ioengine=libaio \
  --iodepth=32 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

# ------------------------------------------------------------
echo -e "${GREEN}[4/4] Random 4K Read Test (Docker/AI/database workload)${NC}"
echo "" >> $RESULTS
echo "--- Random 4K Read (IOPS test, 4 jobs) ---" >> $RESULTS

fio --name=arctic-rand-read \
  --filename=$TESTFILE \
  --rw=randread \
  --bs=4k \
  --size=4G \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --direct=1 \
  --ioengine=libaio \
  --iodepth=32 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

# ------------------------------------------------------------
echo -e "${CYAN}[btrfs] Filesystem info and stats${NC}"
echo "" >> $RESULTS
echo "--- btrfs Filesystem Info ---" >> $RESULTS
btrfs filesystem show $POOL >> $RESULTS
echo "" >> $RESULTS
echo "--- btrfs Filesystem Usage ---" >> $RESULTS
btrfs filesystem df $POOL >> $RESULTS
echo "" >> $RESULTS
echo "--- btrfs Device Stats (errors) ---" >> $RESULTS
btrfs device stats $POOL >> $RESULTS

# ------------------------------------------------------------
# NVMe SMART data for Arctic drive
echo -e "${CYAN}[NVMe] SMART health data${NC}"
echo "" >> $RESULTS
echo "--- NVMe SMART Log (nvme0n1) ---" >> $RESULTS
nvme smart-log /dev/nvme0n1 >> $RESULTS 2>&1

# ------------------------------------------------------------
# Cleanup
echo -e "${YELLOW}[Cleanup] Removing test file...${NC}"
rm -f $TESTFILE

# Summary
echo ""
echo -e "${CYAN}"
echo "============================================================"
echo "  Benchmark Complete!"
echo "  Results saved to: $RESULTS"
echo "  Open Netdata: http://$(hostname -I | awk '{print $1}'):19999"
echo "============================================================"
echo -e "${NC}"

# Quick results summary
echo -e "${GREEN}=== QUICK SUMMARY ===${NC}"
grep -E "READ:|WRITE:|iops|bw=" $RESULTS | head -20
