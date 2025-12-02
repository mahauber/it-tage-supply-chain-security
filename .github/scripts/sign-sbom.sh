#!/bin/bash
set -e

IMAGE_REF="${1}"
KEY_REF="${2}"
SBOM_FILE="${3}"

echo "➡️   Signing SBOM..."
cosign attest -y --key "${KEY_REF}" --type cyclonedx --predicate "${SBOM_FILE}" "${IMAGE_REF}"
