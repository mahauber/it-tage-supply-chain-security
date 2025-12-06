#!/bin/bash
set -euo pipefail

# Default values
IMAGE_REF=""
OUTPUT_FILE="sbom.cdx.json"
FORMAT="cyclonedx"

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_REF [--output OUTPUT_FILE] [--format FORMAT]

Generate Software Bill of Materials (SBOM) for container image.

Required arguments:
  --image IMAGE_REF        Container image reference

Optional arguments:
  --output OUTPUT_FILE     Output file path (default: sbom.cdx.json)
  --format FORMAT          SBOM format: cyclonedx or spdx (default: cyclonedx)
  --help                   Show this help message

Example:
  $0 --image myregistry.azurecr.io/app@sha256:abc123 --output app-sbom.json
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
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --format)
      FORMAT="$2"
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

# Validate format
if [[ "${FORMAT}" != "cyclonedx" && "${FORMAT}" != "spdx" ]]; then
  echo "ERROR: Invalid format: ${FORMAT}. Must be 'cyclonedx' or 'spdx'" >&2
  exit 1
fi

# Validate output file extension
if [[ "${FORMAT}" == "cyclonedx" && ! "${OUTPUT_FILE}" =~ \.json$ ]]; then
  echo "WARNING: CycloneDX format typically uses .json extension" >&2
fi

echo "➡️   Generating SBOM..."
echo "    Image: ${IMAGE_REF}"
echo "    Format: ${FORMAT}"
echo "    Output: ${OUTPUT_FILE}"

trivy image --format "${FORMAT}" --output "${OUTPUT_FILE}" "${IMAGE_REF}"

if [[ ! -f "${OUTPUT_FILE}" ]]; then
  echo "ERROR: Failed to generate SBOM" >&2
  exit 1
fi

echo "✅ Successfully generated SBOM: ${OUTPUT_FILE}"
