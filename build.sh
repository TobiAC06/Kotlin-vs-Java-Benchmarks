#!/usr/bin/env bash
# =====================================================================
#  build.sh – Build the JMH benchmark Docker image
#
#  Usage:
#    ./build.sh            # build with default tag
#    ./build.sh my-tag     # build with custom tag
# =====================================================================

set -euo pipefail

IMAGE_NAME_BENCH="jmh-benchmarks"
IMAGE_NAME_ANALYSE="jmh-analyse"
TAG="${1:-latest}"
FULL_BENCH_TAG="${IMAGE_NAME_BENCH}:${TAG}"
FULL_ANALYSE_TAG="${IMAGE_NAME_ANALYSE}:${TAG}"

echo "==> Building Docker image for running the Benchmarks: ${FULL_BENCH_TAG}"
docker build \
  --target run \
  --tag "${FULL_BENCH_TAG}" \
  --file Dockerfile \
  .

echo "==> Building Docker image for analysing the Benchmarks: ${FULL_ANALYSE_TAG}"
docker build \
  --target analyse \
  --tag "${FULL_ANALYSE_TAG}" \
  --file Dockerfile \
  .

echo ""
echo "==> Images built successfully"
echo "Run benchmarks with:  ./run.sh"