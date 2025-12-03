#!/bin/bash
set -euo pipefail

# Parameters
IMAGE_REF="${1}"

# Secrets via environment variable
if [[ -z "${COSIGN_KEY_REF:-}" ]]; then
  echo "ERROR: COSIGN_KEY_REF environment variable not set"
  exit 1
fi

# Input validation
if [[ -z "${IMAGE_REF}" ]]; then
  echo "ERROR: IMAGE_REF parameter required"
  exit 1
fi

echo "➡️   Signing Docker image..."
cosign sign -y --key "${COSIGN_KEY_REF}" "${IMAGE_REF}"
