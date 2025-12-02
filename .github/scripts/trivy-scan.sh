#!/bin/bash
set -e

IMAGE_REF="${1}"
SEVERITY="${2:-CRITICAL,HIGH}"

echo "➡️   Scanning image for vulnerabilities..."
trivy image --severity "${SEVERITY}" --exit-code 1 --no-progress "${IMAGE_REF}"
