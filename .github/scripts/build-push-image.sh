#!/bin/bash
set -e

IMAGE_NAME="${1}"
BUILD_CONTEXT="${2}"
PLATFORMS="${3:-linux/amd64,linux/arm/v7,linux/arm64}"

echo "➡️   Building and pushing multi-platform images..."
docker buildx build \
  --platform "${PLATFORMS}" \
  --push \
  -t "${IMAGE_NAME}" \
  "${BUILD_CONTEXT}"
