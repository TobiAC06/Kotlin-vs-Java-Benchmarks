#!/usr/bin/env bash
# =====================================================================
#  build.sh – Build the JMH benchmark Docker image
#
#  Usage:
#    ./build.sh            # build with default tag
#    ./build.sh my-tag     # build with custom tag
# =====================================================================

set -euo pipefail

IMAGE_NAME="jmh-benchmarks"
TAG="${1:-latest}"
FULL_TAG="${IMAGE_NAME}:${TAG}"

echo "==> Building Docker image: ${FULL_TAG}"
docker build \
  --target run \
  --tag "${FULL_TAG}" \
  --file Dockerfile \
  .

echo ""
echo "✓ Image built successfully: ${FULL_TAG}"
echo "  Run benchmarks with:  ./run.sh"