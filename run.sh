#!/usr/bin/env bash
# =====================================================================
#  run.sh – Run JMH benchmarks inside Docker
#
#  Usage:
#    ./run.sh [OPTIONS] [FILTER]
#
#  Options:
#    -wi <n>      Warmup iterations       (default: 10)
#    -i  <n>      Measurement iterations  (default: 50)
#    -f  <n>      Forks                   (default: 4)
#
#  Filter:
#    Optional benchmark name / regex (last positional argument).
#
#  Examples:
#    ./run.sh                              # full run with defaults
#    ./run.sh Sieve                        # Sieve benchmarks only
#    ./run.sh -wi 3 -i 5 -f 1             # quick smoke-test
#    ./run.sh -wi 3 -i 5 -f 1 Boxing      # smoke-test, Boxing only
#    ./run.sh "Boxing|Lambda"              # multiple scenarios
# =====================================================================
set -euo pipefail

IMAGE_NAME="jmh-benchmarks:latest"
RESULTS_DIR="$(pwd)/results"

# ── Defaults (mirrors build.gradle.kts) ──────────────────────────────
DEFAULT_WI=10
DEFAULT_I=50
DEFAULT_F=4

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

# ── Assemble JMH arguments ────────────────────────────────────────────
JMH_ARGS=(
  "-wi" "$WI"
  "-i"  "$I"
  "-f"  "$F"
  "-prof" "gc"
  "-v"    "EXTRA"
  "-rff"  "results/jmh-results.json"
  "-rf"   "json"
)

[[ -n "$FILTER" ]] && JMH_ARGS+=("$FILTER")

# ── Print summary ─────────────────────────────────────────────────────
echo "==> Image:   ${IMAGE_NAME}"
echo "==> Filter:  ${FILTER:-<all benchmarks>}"
echo "==> Warmup:  ${WI} iterations"
echo "==> Iters:   ${I} iterations"
echo "==> Forks:   ${F}"
echo "==> Results: ${RESULTS_DIR}/jmh-results.json"
echo ""

docker run --rm \
  --volume "${RESULTS_DIR}:/benchmarks/results" \
  --cpus "2" \
  "${IMAGE_NAME}" \
  "${JMH_ARGS[@]}"

echo ""
echo "✓ Benchmarks complete."
echo "  Results: ${RESULTS_DIR}/jmh-results.json"