#!/bin/bash
set -euo pipefail

# Default values
PLATFORMS="linux/amd64,linux/arm64"
IMAGE_NAME=""
BUILD_CONTEXT=""
PUSH="false"
LOAD="false"

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_NAME --build-context BUILD_CONTEXT [--platforms PLATFORMS] [--push|--load]

Build multi-platform Docker images.

Required arguments:
  --image IMAGE_NAME              Full image name with tag (e.g., myregistry.azurecr.io/app:v1.0)
  --build-context BUILD_CONTEXT   Path to the build context directory

Optional arguments:
  --platforms PLATFORMS           Comma-separated list of platforms (default: linux/amd64,linux/arm64)
  --push                          Push the image to registry
  --load                          Load image into Docker (only works with single platform)
  --help                          Show this help message

Example:
  $0 --image myregistry.azurecr.io/app:latest --build-context ./app --platforms linux/amd64 --load
  $0 --image myregistry.azurecr.io/app:latest --build-context ./app --platforms linux/amd64,linux/arm64 --push
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
    --build-context)
      BUILD_CONTEXT="$2"
      shift 2
      ;;
    --platforms)
      PLATFORMS="$2"
      shift 2
      ;;
    --push)
      PUSH="true"
      shift
      ;;
    --load)
      LOAD="true"
      shift
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

if [[ "${PUSH}" == "true" && "${LOAD}" == "true" ]]; then
  echo "ERROR: Cannot use both --push and --load" >&2
  exit 1
fi

if [[ "${PUSH}" == "true" ]]; then
  echo "➡️   Building and pushing multi-platform images..."
elif [[ "${LOAD}" == "true" ]]; then
  echo "➡️   Building and loading image into Docker..."
else
  echo "➡️   Building multi-platform images..."
fi

echo "    Image: ${IMAGE_NAME}"
echo "    Context: ${BUILD_CONTEXT}"
echo "    Platforms: ${PLATFORMS}"
echo "    Push: ${PUSH}"
echo "    Load: ${LOAD}"

BUILD_ARGS=(
  --platform "${PLATFORMS}"
  -t "${IMAGE_NAME}"
)

if [[ "${PUSH}" == "true" ]]; then
  BUILD_ARGS+=(--push)
elif [[ "${LOAD}" == "true" ]]; then
  # Validate single platform for --load
  PLATFORM_COUNT=$(echo "${PLATFORMS}" | tr ',' '\n' | wc -l)
  if [[ ${PLATFORM_COUNT} -gt 1 ]]; then
    echo "ERROR: --load only supports single platform builds" >&2
    echo "Current platforms: ${PLATFORMS}" >&2
    exit 1
  fi
  BUILD_ARGS+=(--load)
fi

docker buildx build "${BUILD_ARGS[@]}" "${BUILD_CONTEXT}"

if [[ "${PUSH}" == "true" ]]; then
  echo "✅ Successfully built and pushed: ${IMAGE_NAME}"
elif [[ "${LOAD}" == "true" ]]; then
  echo "✅ Successfully built and loaded: ${IMAGE_NAME}"
else
  echo "✅ Successfully built: ${IMAGE_NAME}"
fi
