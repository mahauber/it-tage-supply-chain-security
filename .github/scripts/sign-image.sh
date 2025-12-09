#!/bin/bash
set -euo pipefail
set -o xtrace

# Default values
IMAGE_REF=""
COSIGN_KEY_REF=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_REF --key COSIGN_KEY_REF

Sign container image using Cosign.

Required arguments:
  --image IMAGE_REF        Container image reference with digest
  --key COSIGN_KEY_REF     Cosign key reference (e.g., azurekms://...)
  --help                   Show this help message

Example:
  $0 --image myregistry.azurecr.io/app@sha256:abc123 --key azurekms://...
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
    --key)
      COSIGN_KEY_REF="$2"
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

if [[ -z "${COSIGN_KEY_REF}" ]]; then
  echo "ERROR: Cosign key reference is required (--key flag)" >&2
  usage
fi

# Validate image reference contains digest
if [[ ! "${IMAGE_REF}" =~ @sha256: ]]; then
  echo "ERROR: Image reference must include digest (@sha256:...)" >&2
  exit 1
fi

echo "➡️   Signing Docker image..."
echo "    Image: ${IMAGE_REF}"

COSIGN_EXPERIMENTAL=1 cosign sign -y --key azurekms://kv-supply-chain-demo.vault.azure.net/github-actions-cosign-key-simple-service/384dfd5ac2bc48da9c7e674bdfe952d8 "${IMAGE_REF}" --verbose
echo "✅ Successfully signed image: ${IMAGE_REF}"
