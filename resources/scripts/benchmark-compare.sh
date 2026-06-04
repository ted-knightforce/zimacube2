#!/bin/bash
# ============================================================
# ZimaCube 2 Pioneer Build — Combined Benchmark Comparison
# Glacier ZFS RAIDZ1 (OCuLink) vs Arctic-Storage btrfs (7th Bay)
# ============================================================

GLACIER="/media/glacier"
ARCTIC="/media/Arctic-Storage"
SUMMARY="/root/benchmark-comparison-summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colours
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}"
echo "============================================================"
echo "  ZimaCube 2 Pioneer Build — Full Storage Comparison"
echo "  Glacier ZFS RAIDZ1 vs Arctic-Storage btrfs PCIe 5.0"
echo "  Started: $TIMESTAMP"
echo "============================================================"
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}⚠️  Please run as root: sudo -i then ./benchmark-compare.sh${NC}"
  exit 1
fi

# Check fio
if ! command -v fio &> /dev/null; then
  echo -e "${YELLOW}⚠️  fio not found on ZimaOS.${NC}"
  echo -e "${YELLOW}    Run fio via Docker container instead:${NC}"
  echo -e "${YELLOW}    docker run --rm -v /media:/media nixery.dev/shell/fio fio --help${NC}"
  exit 1
fi

# Declare result arrays
declare -A RESULTS

run_test() {
  local NAME=$1
  local FILE=$2
  local RW=$3
  local BS=$4
  local JOBS=$5
  local DEPTH=$6
  local SIZE=$7

  echo -e "${GREEN}  Running: $NAME${NC}"

  OUTPUT=$(fio --name=$NAME \
    --filename=$FILE \
    --rw=$RW \
    --bs=$BS \
    --size=$SIZE \
    --numjobs=$JOBS \
    --runtime=60 \
    --time_based \
    --direct=1 \
    --ioengine=libaio \
    --iodepth=$DEPTH \
    --group_reporting \
    --output-format=normal 2>&1)

  # Extract bandwidth
  BW=$(echo "$OUTPUT" | grep -E "bw=" | grep -oP 'bw=\K[^,]+' | head -1)
  IOPS=$(echo "$OUTPUT" | grep -oP 'IOPS=\K[^,]+' | head -1)

  RESULTS[$NAME]="BW: $BW | IOPS: $IOPS"
  echo "$OUTPUT"
}

# ============================================================
echo -e "${BOLD}${CYAN}"
echo "============================================================"
echo "  PHASE 1 — Glacier ZFS RAIDZ1 (OCuLink)"
echo "  4x 2TB XPG GAMMIX S70 BLADE PCIe 4.0"
echo "============================================================"
echo -e "${NC}"

GLACIER_FILE="$GLACIER/fio-benchmark.tmp"

run_test "glacier-seq-write"  $GLACIER_FILE write   1M  4  8  8G
run_test "glacier-seq-read"   $GLACIER_FILE read    1M  4  8  8G
run_test "glacier-rand-write" $GLACIER_FILE randwrite 4k 4 32 4G
run_test "glacier-rand-read"  $GLACIER_FILE randread  4k 4 32 4G

rm -f $GLACIER_FILE
echo -e "${YELLOW}  Glacier test file cleaned up${NC}"

# ZFS specific stats
echo -e "${CYAN}  ZFS Pool Stats:${NC}"
zpool list glacier
zfs get compressratio glacier

# ============================================================
echo -e "${BOLD}${CYAN}"
echo "============================================================"
echo "  PHASE 2 — Arctic-Storage btrfs PCIe 5.0 (7th Bay)"
echo "  1x Crucial P510 2TB PCIe 5.0 NVMe"
echo "============================================================"
echo -e "${NC}"

ARCTIC_FILE="$ARCTIC/fio-benchmark.tmp"

run_test "arctic-seq-write"  $ARCTIC_FILE write   1M  4  8  8G
run_test "arctic-seq-read"   $ARCTIC_FILE read    1M  4  8  8G
run_test "arctic-rand-write" $ARCTIC_FILE randwrite 4k 4 32 4G
run_test "arctic-rand-read"  $ARCTIC_FILE randread  4k 4 32 4G

rm -f $ARCTIC_FILE
echo -e "${YELLOW}  Arctic test file cleaned up${NC}"

# btrfs specific stats
echo -e "${CYAN}  btrfs Filesystem Stats:${NC}"
btrfs filesystem df $ARCTIC

# ============================================================
echo -e "${BOLD}${CYAN}"
echo "============================================================"
echo "  BENCHMARK COMPARISON SUMMARY"
echo "  ZimaCube 2 Pioneer Build — $(date '+%Y-%m-%d')"
echo "============================================================"
echo -e "${NC}"

# Write summary file
cat > $SUMMARY << EOF
============================================================
  ZimaCube 2 Pioneer Build — Benchmark Comparison Summary
  Date: $TIMESTAMP
============================================================

SETUP:
  Glacier  — ZFS RAIDZ1, 4x 2TB PCIe 4.0 NVMe via OCuLink (Aoostar TB4S-OC)
  Arctic   — btrfs single, 1x 2TB PCIe 5.0 NVMe (7th Bay, 800MB/s cap)

------------------------------------------------------------
TEST                    GLACIER (ZFS RAIDZ1)    ARCTIC (btrfs PCIe 5.0)
------------------------------------------------------------
Sequential Write        ${RESULTS[glacier-seq-write]}
                                                ${RESULTS[arctic-seq-write]}
Sequential Read         ${RESULTS[glacier-seq-read]}
                                                ${RESULTS[arctic-seq-read]}
Random 4K Write         ${RESULTS[glacier-rand-write]}
                                                ${RESULTS[arctic-rand-write]}
Random 4K Read          ${RESULTS[glacier-rand-read]}
                                                ${RESULTS[arctic-rand-read]}
------------------------------------------------------------

NOTES:
  - Glacier: 4 drives in RAIDZ1 = ~1 drive parity overhead on writes
  - Glacier: Reads stripe across all 4 drives = higher read throughput
  - Arctic: Single PCIe 5.0 drive capped at 800MB/s by 7th Bay bridge
  - Arctic: No redundancy — single point of failure
  - ZFS ARC cache benefits random reads significantly over time
  - Monitor at: http://$(hostname -I | awk '{print $1}'):19999

============================================================
EOF

cat $SUMMARY

echo -e "${GREEN}"
echo "  Summary saved to: $SUMMARY"
echo "  Netdata dashboard: http://$(hostname -I | awk '{print $1}'):19999"
echo -e "${NC}"
