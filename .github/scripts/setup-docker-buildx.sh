#!/bin/bash
set -euo pipefail

# Default values
BUILDER_NAME="multiarch"
DRIVER="docker-container"

# Usage function
usage() {
  cat <<EOF
Usage: $0 [--name NAME] [--driver DRIVER]

Set up Docker Buildx for multi-platform builds.

Optional arguments:
  --name NAME          Builder instance name (default: multiarch)
  --driver DRIVER      Builder driver (default: docker-container)
  --help               Show this help message

Example:
  $0 --name multiarch --driver docker-container
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      BUILDER_NAME="$2"
      shift 2
      ;;
    --driver)
      DRIVER="$2"
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

# Validate builder name
if [[ ! "${BUILDER_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "ERROR: Invalid builder name: ${BUILDER_NAME}" >&2
  echo "Builder name must contain only alphanumeric characters, hyphens, and underscores" >&2
  exit 1
fi

# Validate driver
if [[ "${DRIVER}" != "docker-container" && "${DRIVER}" != "kubernetes" && "${DRIVER}" != "docker" ]]; then
  echo "ERROR: Invalid driver: ${DRIVER}" >&2
  echo "Supported drivers: docker-container, kubernetes, docker" >&2
  exit 1
fi

echo "➡️   Setting up Docker Buildx (${BUILDER_NAME}, ${DRIVER})..."

# Remove existing builder if it exists
if docker buildx ls | grep -q "${BUILDER_NAME}"; then
  echo "Removing existing builder: ${BUILDER_NAME}"
  docker buildx rm "${BUILDER_NAME}" || true
fi

docker buildx create --name "${BUILDER_NAME}" --driver "${DRIVER}" --use
docker buildx inspect --bootstrap
echo "✅ Successfully set up Docker Buildx: ${BUILDER_NAME}"
