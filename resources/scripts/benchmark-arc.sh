#!/bin/bash
# ============================================================
# ZimaCube 2 Build — ZFS ARC Full Benchmark
# Target: Glacier ZFS RAIDZ1 Pool (OCuLink)
# Purpose: Measure write throughput AND read performance
#          with and without warm ZFS ARC cache
# ============================================================
# Method:
#   1. Capture ARC state before test (hits / misses / size)
#   2. Sequential Write     (--direct=1, 4 jobs, 1M blocks, 60s)
#   3. Random 4K Write      (--direct=1, 4 jobs, 4k blocks, 60s)
#   4. Warm-up pass         — sequential read, no --direct
#                             (populates ARC with test file data)
#   5. Random 4K Read       — Warm ARC (requests from RAM)
#   6. Capture ARC state after test — show delta + iostat
#   7. Random 4K Read       — Cold baseline (--direct=1, bypasses ARC)
# ============================================================
# Note on writes:
#   ZFS ARC caches reads, not writes. Steps 2 and 3 use
#   --direct=1 to bypass the OS page cache and measure raw
#   ZFS pool write throughput. Results are directly comparable
#   to benchmark-glacier.sh write figures.
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
echo "  ZimaCube 2 Build — ZFS ARC Full Benchmark"
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
echo "  ZFS ARC Full Benchmark Results" >> $RESULTS
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
# STEP 2 — Sequential Write (--direct=1, bypasses page cache)
#          ARC is not involved in write operations.
#          Measures raw ZFS RAIDZ1 write throughput.
# ============================================================

echo ""
echo -e "${GREEN}[1/4] Sequential Write (1M blocks, 4 jobs, 60s, --direct=1)${NC}"
echo -e "${YELLOW}      ARC does not cache writes — direct ZFS pool throughput${NC}"
echo "" >> $RESULTS
echo "--- Sequential Write (--direct=1, 4 jobs, 1M blocks) ---" >> $RESULTS

fio --name=arc-seqwrite \
  --filename=$TESTFILE \
  --rw=write \
  --bs=1M \
  --size=$TESTSIZE \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --ioengine=libaio \
  --iodepth=8 \
  --direct=1 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

# ============================================================
# STEP 3 — Random 4K Write (--direct=1)
#          Measures random write IOPS at queue depth 32.
#          Comparable to benchmark-glacier.sh rand write test.
# ============================================================

echo ""
echo -e "${GREEN}[2/4] Random 4K Write (4k blocks, 4 jobs, 60s, --direct=1)${NC}"
echo -e "${YELLOW}      ARC does not cache writes — direct ZFS pool throughput${NC}"
echo "" >> $RESULTS
echo "--- Random 4K Write (--direct=1, 4 jobs, 4k blocks) ---" >> $RESULTS

fio --name=arc-randwrite \
  --filename=$TESTFILE \
  --rw=randwrite \
  --bs=4k \
  --size=$TESTSIZE \
  --numjobs=4 \
  --runtime=60 \
  --time_based \
  --ioengine=libaio \
  --iodepth=32 \
  --direct=1 \
  --group_reporting \
  --output-format=normal 2>&1 | tee -a $RESULTS

# ============================================================
# STEP 4 — Warm-up: Sequential Read (populates ARC)
# ============================================================

echo ""
echo -e "${GREEN}[Warmup] Sequential Read — populating ARC (no --direct)${NC}"
echo -e "${YELLOW}         This pass loads the test file into ARC (RAM)${NC}"
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
# STEP 5 — Random 4K Read — Warm ARC (served from RAM)
# ============================================================

echo ""
echo -e "${GREEN}[3/4] Random 4K Read — Warm ARC (no --direct=1)${NC}"
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
# STEP 6 — Capture ARC state after benchmark
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
echo "--- zpool iostat (actual NVMe disk activity during warm read) ---" >> $RESULTS
echo "    Low read MB/s here = ARC served the requests" >> $RESULTS
cat $RESULTS.iostat >> $RESULTS
rm -f $RESULTS.iostat

# ============================================================
# STEP 7 — Cold baseline: Random 4K Read (--direct=1)
# ============================================================

echo ""
echo -e "${GREEN}[4/4] Random 4K Read — Cold baseline (--direct=1)${NC}"
echo -e "${YELLOW}      Bypasses ARC — raw NVMe disk throughput for direct comparison${NC}"
echo "" >> $RESULTS
echo "--- Random 4K Read — Cold Baseline (--direct=1, bypasses ARC) ---" >> $RESULTS

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
echo "  ARC Full Benchmark Complete!"
echo "  Results saved to: $RESULTS"
echo "============================================================"
echo -e "${NC}"

echo -e "${GREEN}=== SESSION ARC SUMMARY ===${NC}"
echo -e "  ARC size before : $ARC_SIZE_BEFORE"
echo -e "  ARC size after  : $ARC_SIZE_AFTER"
echo -e "  Session hit rate: ${CYAN}$HIT_RATE_SESSION${NC}"
echo ""
echo -e "${GREEN}=== QUICK RESULTS ===${NC}"
echo -e "${YELLOW}  Writes (ARC not involved — direct ZFS pool):${NC}"
grep -A4 "arc-seqwrite\|arc-randwrite" $RESULTS | grep -E "WRITE:|iops|bw=" | head -8
echo ""
echo -e "${YELLOW}  Reads:${NC}"
grep -A4 "arc-randread-warm\|arc-warmup\|arc-randread-cold" $RESULTS | grep -E "READ:|iops|bw=" | head -12
