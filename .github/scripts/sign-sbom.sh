#!/bin/bash
set -euo pipefail

# Parameters
IMAGE_REF="${1}"
SBOM_FILE="${2}"

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

if [[ -z "${SBOM_FILE}" ]]; then
  echo "ERROR: SBOM_FILE parameter required"
  exit 1
fi

if [[ ! -f "${SBOM_FILE}" ]]; then
  echo "ERROR: SBOM file ${SBOM_FILE} not found"
  exit 1
fi

echo "➡️   Signing SBOM..."
cosign attest -y --key "${COSIGN_KEY_REF}" --type cyclonedx --predicate "${SBOM_FILE}" "${IMAGE_REF}"
