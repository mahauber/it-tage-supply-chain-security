#!/bin/bash
set -euo pipefail

# Default values
IMAGE_REF=""
SBOM_FILE=""
SBOM_TYPE="cyclonedx"
COSIGN_KEY_REF=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_REF --sbom-file SBOM_FILE --key COSIGN_KEY_REF [--sbom-type TYPE]

Sign SBOM and attach to container image using Cosign.

Required arguments:
  --image IMAGE_REF        Container image reference with digest
  --sbom-file SBOM_FILE    Path to SBOM file
  --key COSIGN_KEY_REF     Cosign key reference (e.g., azurekms://...)

Optional arguments:
  --sbom-type TYPE         SBOM type: cyclonedx or spdx (default: cyclonedx)
  --help                   Show this help message

Example:
  $0 --image myregistry.azurecr.io/app@sha256:abc --sbom-file sbom.json --key azurekms://...
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
    --sbom-file)
      SBOM_FILE="$2"
      shift 2
      ;;
    --sbom-type)
      SBOM_TYPE="$2"
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

if [[ -z "${SBOM_FILE}" ]]; then
  echo "ERROR: SBOM file is required (--sbom-file flag)" >&2
  usage
fi

if [[ -z "${COSIGN_KEY_REF}" ]]; then
  echo "ERROR: Cosign key reference is required (--key flag)" >&2
  usage
fi

# Validate SBOM file exists
if [[ ! -f "${SBOM_FILE}" ]]; then
  echo "ERROR: SBOM file not found: ${SBOM_FILE}" >&2
  exit 1
fi

# Validate SBOM type
if [[ "${SBOM_TYPE}" != "cyclonedx" && "${SBOM_TYPE}" != "spdx" ]]; then
  echo "ERROR: Invalid SBOM type: ${SBOM_TYPE}. Must be 'cyclonedx' or 'spdx'" >&2
  exit 1
fi

# Validate image reference contains digest
if [[ ! "${IMAGE_REF}" =~ @sha256: ]]; then
  echo "ERROR: Image reference must include digest (@sha256:...)" >&2
  exit 1
fi

echo "➡️   Signing SBOM..."
echo "    Image: ${IMAGE_REF}"
echo "    SBOM File: ${SBOM_FILE}"
echo "    SBOM Type: ${SBOM_TYPE}"

cosign attest -y --key "${COSIGN_KEY_REF}" --type "${SBOM_TYPE}" --predicate "${SBOM_FILE}" "${IMAGE_REF}"
echo "✅ Successfully signed and attached SBOM to image"
