#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORETOP="$PROJECT_ROOT/nscscc-solo-la-soc/rtl/ip/myCPU/core_top.sv"
NEMU_MK="$PROJECT_ROOT/la32r-nemu/NEMU/scripts/build.mk"
RESULTS="$PROJECT_ROOT/experiments/dcache_sweep_results.txt"

declare -A LOG2_MAP
LOG2_MAP[256]=8
LOG2_MAP[512]=9
LOG2_MAP[1024]=10
LOG2_MAP[2048]=11
LOG2_MAP[4096]=12

SIZES=(256 512 1024 2048 4096)
TESTS=(simple stream matrix mixed cryptonight)

bak_coretop=$(cat "$CORETOP")
bak_nemu_mk=$(cat "$NEMU_MK")

restore() {
  echo ""
  echo "=== Restoring original files ==="
  echo "$bak_coretop" > "$CORETOP"
  echo "$bak_nemu_mk" > "$NEMU_MK"
}
trap restore EXIT

echo "=== DCache Set Count Sweep ===" | tee "$RESULTS"
echo "Started: $(date)" | tee -a "$RESULTS"
echo "Sizes:  ${SIZES[*]}" | tee -a "$RESULTS"
echo "Tests:  ${TESTS[*]}" | tee -a "$RESULTS"
echo ""

printf "%-8s" "Size"
for t in "${TESTS[@]}"; do printf " %-12s" "$t"; done
echo
printf "%-8s" "------"
for t in "${TESTS[@]}"; do printf " %-12s" "------"; done
echo

for size in "${SIZES[@]}"; do
  index_bits="${LOG2_MAP[$size]}"
  echo "[$(date +%H:%M:%S)] DCACHE_SETS=$size (index_bits=$index_bits)"

  sed -i "s/parameter int DCACHE_SETS = [0-9]*/parameter int DCACHE_SETS = $size/" "$CORETOP"
  sed -i "s/-DDCACHE_INDEX_BITS=[0-9]*/-DDCACHE_INDEX_BITS=$index_bits/" "$NEMU_MK"

  echo "  Rebuilding NEMU..."
  make -C "$PROJECT_ROOT/difftest" build -j"$(nproc)" 2>&1 | tail -3 || {
    echo "  ERROR: NEMU rebuild failed" | tee -a "$RESULTS"
    continue
  }

  hit_rates=()
  for test in "${TESTS[@]}"; do
    echo -n "  test-$test..."
    output=$(FORCE_VERILATOR_REBUILD=1 make test-"$test" -C "$PROJECT_ROOT" 2>&1) || true
    hit_line=$(echo "$output" | grep 'DCache:' | grep 'hit_rate=' | tail -1 || echo "")
    hit_rate=$(echo "$hit_line" | sed -n 's/.*hit_rate=\([0-9.]*\)%.*/\1/p')
    if [ -z "$hit_rate" ]; then
      hit_rate="N/A"
      echo " FAIL"
    else
      echo " ${hit_rate}%"
    fi
    hit_rates+=("$hit_rate")
  done

  printf "%-8s" "$size"
  for r in "${hit_rates[@]}"; do printf " %-12s" "$r"; done
  echo
  echo "$size ${hit_rates[*]}" >> "$RESULTS"
done

echo ""
echo "=== Finished: $(date) ===" | tee -a "$RESULTS"
echo "Results saved to: $RESULTS"
