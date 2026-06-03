#!/bin/bash
# ============================================================
# ZimaCube 2 Build — ZFS ARC Warm Cache Benchmark
# Target: Glacier ZFS RAIDZ1 Pool (OCuLink)
# Purpose: Measure real-world read performance when ZFS ARC
#          is warm — compare against cold-cache baseline
# ============================================================
# Method:
#   1. Capture ARC state before test (hits / misses / size)
#   2. Warm-up pass  — sequential read without O_DIRECT
#      (populates ARC with test file data)
#   3. Benchmark     — random 4K read without O_DIRECT
#      (requests served from ARC, not NVMe)
#   4. Capture ARC state after test — show delta
#   5. zpool iostat  — confirms how little went to actual disk
# ============================================================

POOL="/media/glacier"
TESTFILE="$POOL/fio-arc-test.tmp"
RESULTS="$POOL/benchmark-results-arc.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TESTSIZE="8G"   # Must fit within ARC max (14.37 GiB on 16 GB system)

# Colours
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${CYAN}"
echo "============================================================"
echo "  ZimaCube 2 Build — ZFS ARC Warm Cache Benchmark"
echo "  Glacier ZFS RAIDZ1 — OCuLink via Aoostar TB4S-OC"
echo "  Test size: $TESTSIZE  |  Started: $TIMESTAMP"
echo "============================================================"
echo -e "${NC}"

# --- Pre-flight checks ---

if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}⚠️  Please run as root: sudo -i then ./benchmark-arc.sh${NC}"
  exit 1
fi

if ! command -v fio &> /dev/null; then
  echo -e "${YELLOW}⚠️  fio not found. Check ZimaOS native tools.${NC}"
  exit 1
fi

if [ ! -d "$POOL" ]; then
  echo -e "${YELLOW}⚠️  Glacier pool not found at $POOL${NC}"
  exit 1
fi

if [ ! -f /proc/spl/kstat/zfs/arcstats ]; then
  echo -e "${YELLOW}⚠️  ZFS arcstats not found — is the ZFS module loaded?${NC}"
  exit 1
fi

# --- Results header ---

echo "============================================================" > $RESULTS
echo "  ZFS ARC Warm Cache Benchmark Results" >> $RESULTS
echo "  Date: $TIMESTAMP" >> $RESULTS
echo "  Pool: $POOL | Test file: $TESTSIZE" >> $RESULTS
echo "============================================================" >> $RESULTS

# ============================================================
# STEP 1 — Capture ARC state before test
# ============================================================

echo -e "${BLUE}[ARC] Capturing baseline ARC state...${NC}"
echo "" >> $RESULTS
echo "--- ARC State BEFORE Benchmark ---" >> $RESULTS

ARC_BEFORE=$(cat /proc/spl/kstat/zfs/arcstats | grep -E "^(hits|misses|size|c_max) ")
echo "$ARC_BEFORE" | tee -a $RESULTS

HITS_BEFORE=$(echo "$ARC_BEFORE"  | awk '/^hits/   {print $3}')
MISSES_BEFORE=$(echo "$ARC_BEFORE" | awk '/^misses/ {print $3}')
ARC_SIZE_BEFORE=$(echo "$ARC_BEFORE" | awk '/^size/ {printf "%.2f GiB", $3/1073741824}')

echo ""
echo -e "${BLUE}  ARC size before: $ARC_SIZE_BEFORE${NC}"
echo -e "${BLUE}  Hit rate before: $(awk "BEGIN{printf \"%.1f%%\", $HITS_BEFORE/($HITS_BEFORE+$MISSES_BEFORE)*100}")${NC}"

# ============================================================
# STEP 2 — Create test file and warm the ARC
# ============================================================

echo ""
echo -e "${GREEN}[1/3] Creating ${TESTSIZE} test file and warming ARC...${NC}"
echo -e "${YELLOW}      This pass populates ARC — no --direct flag, reads go through cache${NC}"
echo "" >> $RESULTS
echo "--- Warm-up Pass (Sequential Read — ARC population) ---" >> $RESULTS

fio --name=arc-warmup \
  --filename=$TESTFILE \
  --rw=read \
  --bs=1M \
  --size=$TESTSIZE \
  --numjobs=1 \
  --ioengine=libaio \
  --iodepth=8 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

echo ""
echo -e "${BLUE}[ARC] ARC state after warm-up:${NC}"
ARC_AFTER_WARMUP=$(cat /proc/spl/kstat/zfs/arcstats | grep -E "^(hits|misses|size) ")
ARC_SIZE_AFTER_WARMUP=$(echo "$ARC_AFTER_WARMUP" | awk '/^size/ {printf "%.2f GiB", $3/1073741824}')
echo -e "${BLUE}  ARC size after warm-up: $ARC_SIZE_AFTER_WARMUP${NC}"

# ============================================================
# STEP 3 — Benchmark: Random 4K read WITH warm ARC
# ============================================================

echo ""
echo -e "${GREEN}[2/3] Random 4K Read — Warm ARC (no --direct=1)${NC}"
echo -e "${YELLOW}      Requests served from ARC in RAM — expect very high IOPS and low latency${NC}"
echo "" >> $RESULTS
echo "--- Random 4K Read — Warm ARC (buffered I/O) ---" >> $RESULTS

# Start zpool iostat in background to capture disk-level activity
zpool iostat glacier 1 60 >> $RESULTS.iostat 2>&1 &
IOSTAT_PID=$!

fio --name=arc-randread-warm \
  --filename=$TESTFILE \
  --rw=randread \
  --bs=4k \
  --size=$TESTSIZE \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --ioengine=libaio \
  --iodepth=32 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

kill $IOSTAT_PID 2>/dev/null
wait $IOSTAT_PID 2>/dev/null

# ============================================================
# STEP 4 — Capture ARC state after benchmark
# ============================================================

echo ""
echo -e "${BLUE}[ARC] Capturing ARC state after benchmark...${NC}"
echo "" >> $RESULTS
echo "--- ARC State AFTER Benchmark ---" >> $RESULTS

ARC_AFTER=$(cat /proc/spl/kstat/zfs/arcstats | grep -E "^(hits|misses|size|c_max) ")
echo "$ARC_AFTER" | tee -a $RESULTS

HITS_AFTER=$(echo "$ARC_AFTER"   | awk '/^hits/   {print $3}')
MISSES_AFTER=$(echo "$ARC_AFTER" | awk '/^misses/ {print $3}')
ARC_SIZE_AFTER=$(echo "$ARC_AFTER" | awk '/^size/ {printf "%.2f GiB", $3/1073741824}')

HITS_DELTA=$(( HITS_AFTER - HITS_BEFORE ))
MISSES_DELTA=$(( MISSES_AFTER - MISSES_BEFORE ))
HIT_RATE_SESSION=$(awk "BEGIN{
  total=$HITS_DELTA+$MISSES_DELTA
  if (total>0) printf \"%.1f%%\", $HITS_DELTA/total*100
  else print \"N/A\"
}")

echo "" >> $RESULTS
echo "--- ARC Session Summary (delta during this benchmark) ---" >> $RESULTS
echo "  Hits during test:   $HITS_DELTA" | tee -a $RESULTS
echo "  Misses during test: $MISSES_DELTA" | tee -a $RESULTS
echo "  Session hit rate:   $HIT_RATE_SESSION" | tee -a $RESULTS
echo "  ARC size after:     $ARC_SIZE_AFTER" | tee -a $RESULTS

# Append iostat summary
echo "" >> $RESULTS
echo "--- zpool iostat (actual NVMe disk activity during benchmark) ---" >> $RESULTS
echo "    Low read MB/s here = ARC served the requests" >> $RESULTS
cat $RESULTS.iostat >> $RESULTS
rm -f $RESULTS.iostat

# ============================================================
# STEP 5 — Reference: cold cache baseline for comparison
# ============================================================

echo ""
echo -e "${GREEN}[3/3] Cold cache reference — Random 4K Read with --direct=1${NC}"
echo -e "${YELLOW}      Same test bypassing ARC — for direct comparison${NC}"
echo "" >> $RESULTS
echo "--- Random 4K Read — Cold Cache (--direct=1, bypasses ARC) ---" >> $RESULTS

fio --name=arc-randread-cold \
  --filename=$TESTFILE \
  --rw=randread \
  --bs=4k \
  --size=$TESTSIZE \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --direct=1 \
  --ioengine=libaio \
  --iodepth=32 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

# ============================================================
# Cleanup
# ============================================================

echo -e "${YELLOW}[Cleanup] Removing test file...${NC}"
rm -f $TESTFILE

# ============================================================
# Summary
# ============================================================

echo ""
echo -e "${CYAN}"
echo "============================================================"
echo "  ARC Benchmark Complete!"
echo "  Results saved to: $RESULTS"
echo "============================================================"
echo -e "${NC}"

echo -e "${GREEN}=== SESSION ARC SUMMARY ===${NC}"
echo -e "  ARC size before : $ARC_SIZE_BEFORE"
echo -e "  ARC size after  : $ARC_SIZE_AFTER"
echo -e "  Session hit rate: ${CYAN}$HIT_RATE_SESSION${NC}"
echo ""
echo -e "${GREEN}=== QUICK RESULTS (warm vs cold) ===${NC}"
grep -E "randread|READ:|iops|bw=" $RESULTS | grep -v "^#" | head -20
