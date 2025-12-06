#!/bin/bash
set -euo pipefail

# Default values
IMAGE_NAME=""
REGISTRY=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_NAME --registry REGISTRY

Push Docker image and get digest.

Required arguments:
  --image IMAGE_NAME       Full image name with tag
  --registry REGISTRY      ACR registry name (without .azurecr.io)
  --help                   Show this help message

Example:
  $0 --image myregistry.azurecr.io/app:latest --registry myregistry
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
    --registry)
      REGISTRY="$2"
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

if [[ -z "${REGISTRY}" ]]; then
  echo "ERROR: Registry is required (--registry flag)" >&2
  usage
fi

# Validate registry name format
if [[ ! "${REGISTRY}" =~ ^[a-zA-Z0-9]+$ ]]; then
  echo "ERROR: Invalid registry name: ${REGISTRY}" >&2
  echo "Registry name should be alphanumeric without domain suffix" >&2
  exit 1
fi

echo "➡️   Pushing Docker image..."
echo "    Image: ${IMAGE_NAME}"
echo "    Registry: ${REGISTRY}"

az acr login --name "${REGISTRY}"
docker push "${IMAGE_NAME}"

echo "➡️   Getting image digest..."
IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${IMAGE_NAME}")

if [[ -z "${IMAGE_DIGEST}" ]]; then
  echo "ERROR: Failed to get image digest" >&2
  exit 1
fi

echo "IMAGE_REF_DIGEST=${IMAGE_DIGEST}" >> $GITHUB_ENV
echo "✅ Successfully pushed image with digest: ${IMAGE_DIGEST}"
