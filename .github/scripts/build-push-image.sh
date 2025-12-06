#!/bin/bash
set -euo pipefail

# Default values
PLATFORMS="linux/amd64,linux/arm64"
IMAGE_NAME=""
BUILD_CONTEXT=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_NAME --context BUILD_CONTEXT [--platforms PLATFORMS]

Build and push multi-platform Docker images.

Required arguments:
  --image IMAGE_NAME         Full image name with tag (e.g., myregistry.azurecr.io/app:v1.0)
  --context BUILD_CONTEXT    Path to the build context directory

Optional arguments:
  --platforms PLATFORMS      Comma-separated list of platforms (default: linux/amd64,linux/arm64)
  --help                     Show this help message

Example:
  $0 --image myregistry.azurecr.io/app:latest --context ./app --platforms linux/amd64,linux/arm64
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --image)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --context)
      BUILD_CONTEXT="$2"
      shift 2
      ;;
    --platforms)
      PLATFORMS="$2"
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Validate required parameters
if [[ -z "${IMAGE_NAME}" ]]; then
  echo "ERROR: Image name is required (--image flag)" >&2
  usage
fi

if [[ -z "${BUILD_CONTEXT}" ]]; then
  echo "ERROR: Build context is required (--context flag)" >&2
  usage
fi

# Validate build context exists
if [[ ! -d "${BUILD_CONTEXT}" ]]; then
  echo "ERROR: Build context directory does not exist: ${BUILD_CONTEXT}" >&2
  exit 1
fi

# Validate Dockerfile exists
if [[ ! -f "${BUILD_CONTEXT}/Dockerfile" ]]; then
  echo "ERROR: Dockerfile not found in build context: ${BUILD_CONTEXT}/Dockerfile" >&2
  exit 1
fi

# Validate platforms format
if [[ ! "${PLATFORMS}" =~ ^[a-z0-9/,]+$ ]]; then
  echo "ERROR: Invalid platforms format: ${PLATFORMS}" >&2
  echo "Expected format: linux/amd64,linux/arm64" >&2
  exit 1
fi

echo "➡️   Building and pushing multi-platform images..."
echo "    Image: ${IMAGE_NAME}"
echo "    Context: ${BUILD_CONTEXT}"
echo "    Platforms: ${PLATFORMS}"

docker buildx build \
  --platform "${PLATFORMS}" \
  --push \
  -t "${IMAGE_NAME}" \
  "${BUILD_CONTEXT}"

echo "✅ Successfully built and pushed: ${IMAGE_NAME}"
