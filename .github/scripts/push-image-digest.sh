#!/bin/bash
set -e

IMAGE_NAME="${1}"
REGISTRY="${2}"

echo "➡️   Pushing Docker image..."
az acr login --name "${REGISTRY}"
docker push "${IMAGE_NAME}"

echo "➡️   Set image reference with digest as output variable..."
IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${IMAGE_NAME}")
echo "IMAGE_REF_DIGEST=${IMAGE_DIGEST}" >> $GITHUB_ENV
echo "Image with digest: ${IMAGE_DIGEST}"
