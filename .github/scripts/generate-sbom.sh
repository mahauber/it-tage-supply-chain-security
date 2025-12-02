#!/bin/bash
set -e

IMAGE_REF="${1}"
OUTPUT_FILE="${2:-sbom.cdx.json}"

echo "➡️   Generating SBOM..."
trivy image --format cyclonedx --output "${OUTPUT_FILE}" "${IMAGE_REF}"
