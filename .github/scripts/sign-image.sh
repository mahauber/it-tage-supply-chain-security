#!/bin/bash
set -euo pipefail

# Default values
IMAGE_REF=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_REF

Sign container image using Cosign.

Required arguments:
  --image IMAGE_REF    Container image reference with digest
  --help               Show this help message

Environment variables:
  COSIGN_KEY_REF       Cosign key reference (required)

Example:
  COSIGN_KEY_REF=azurekms://... $0 --image myregistry.azurecr.io/app@sha256:abc123
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --image)
      IMAGE_REF="$2"
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
if [[ -z "${IMAGE_REF}" ]]; then
  echo "ERROR: Image reference is required (--image flag)" >&2
  usage
fi

# Validate environment variable
if [[ -z "${COSIGN_KEY_REF:-}" ]]; then
  echo "ERROR: COSIGN_KEY_REF environment variable not set" >&2
  exit 1
fi

# Validate image reference contains digest
if [[ ! "${IMAGE_REF}" =~ @sha256: ]]; then
  echo "ERROR: Image reference must include digest (@sha256:...)" >&2
  exit 1
fi

echo "➡️   Signing Docker image..."
echo "    Image: ${IMAGE_REF}"

cosign sign -y --key "${COSIGN_KEY_REF}" "${IMAGE_REF}"
echo "✅ Successfully signed image: ${IMAGE_REF}"
