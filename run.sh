#!/usr/bin/env bash
# =====================================================================
#  run.sh – Run JMH benchmarks and/or analyse results via Docker
#
#  Usage:
#    ./run.sh [bench|analyse|all] [OPTIONS] [FILTER]
#
#  Commands:
#    bench      Run benchmarks only (default when no command is given)
#    analyse    Run the analysis script only (requires existing results)
#    all        Run benchmarks, then analyse
#
#  Options (bench / all only):
#    -wi <n>      Warmup iterations       (default: 10)
#    -i  <n>      Measurement iterations  (default: 50)
#    -f  <n>      Forks                   (default: 4)
#
#  Filter (bench / all only):
#    Optional benchmark name / regex (last positional argument).
#
#  Examples:
#    ./run.sh                              # full benchmark run with defaults
#    ./run.sh all                          # benchmark + analyse
#    ./run.sh analyse                      # analyse existing results
#    ./run.sh Sieve                        # Sieve benchmarks only
#    ./run.sh -wi 3 -i 5 -f 1             # quick smoke-test
#    ./run.sh -wi 3 -i 5 -f 1 Boxing      # smoke-test, Boxing only
#    ./run.sh "Boxing|Lambda"              # multiple scenarios
# =====================================================================

set -euo pipefail

BENCH_IMAGE="jmh-benchmarks:latest"
ANALYSE_IMAGE="jmh-analyse:latest"
RESULTS_DIR="$(pwd)/results"

# ── Defaults ──────────────────────────────────────────────────────────
DEFAULT_WI=10
DEFAULT_I=50
DEFAULT_F=4

# ── Determine command ─────────────────────────────────────────────────
COMMAND="bench"
if [[ $# -gt 0 ]]; then
  case "$1" in
    bench|analyse|all) COMMAND="$1"; shift ;;
  esac
fi

# ── Parse named options ───────────────────────────────────────────────
WI=$DEFAULT_WI
I=$DEFAULT_I
F=$DEFAULT_F

while [[ $# -gt 0 ]]; do
  case "$1" in
    -wi) WI="$2"; shift 2 ;;
    -i)  I="$2";  shift 2 ;;
    -f)  F="$2";  shift 2 ;;
    -*)  echo "Unknown option: $1" >&2; exit 1 ;;
    *)   break ;;   # first non-option arg = filter
  esac
done

FILTER="${1:-}"

mkdir -p "${RESULTS_DIR}"

# ── Helper: run benchmarks ────────────────────────────────────────────
run_bench() {
  local JMH_ARGS=(
    "-wi" "$WI"
    "-i"  "$I"
    "-f"  "$F"
    "-prof" "gc"
    "-v"    "EXTRA"
    "-rff"  "results/jmh-results.json"
    "-rf"   "json"
  )
  [[ -n "$FILTER" ]] && JMH_ARGS+=("$FILTER")

  echo "==> Image:   ${BENCH_IMAGE}"
  echo "==> Filter:  ${FILTER:-<all benchmarks>}"
  echo "==> Warmup:  ${WI} iterations"
  echo "==> Iters:   ${I} iterations"
  echo "==> Forks:   ${F}"
  echo "==> Results: ${RESULTS_DIR}/jmh-results.json"
  echo ""

  docker run --rm \
    --volume "${RESULTS_DIR}:/benchmarks/results" \
    --cpus "2" \
    "${BENCH_IMAGE}" \
    "${JMH_ARGS[@]}"

  echo ""
  echo "✓ Benchmarks complete."
  echo "  Results: ${RESULTS_DIR}/jmh-results.json"
}

# ── Helper: run analysis ──────────────────────────────────────────────
run_analyse() {
  echo "==> Image:   ${ANALYSE_IMAGE}"
  echo "==> Input:   ${RESULTS_DIR}/jmh-results.json"
  echo "==> Output:  ${RESULTS_DIR}/"
  echo ""

  docker run --rm \
    --volume "${RESULTS_DIR}:/results" \
    "${ANALYSE_IMAGE}"

  echo ""
  echo "✓ Analysis complete."
  echo "  benchmark_runtime.png → ${RESULTS_DIR}/benchmark_runtime.png"
  echo "  benchmark_memory.png  → ${RESULTS_DIR}/benchmark_memory.png"
}

# ── Dispatch ──────────────────────────────────────────────────────────
case "$COMMAND" in
  bench)
    run_bench
    ;;
  analyse)
    run_analyse
    ;;
  all)
    run_bench
    echo ""
    run_analyse
    ;;
esac