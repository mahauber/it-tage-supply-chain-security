#!/bin/bash
set -e

IMAGE_REF="${1}"
KEY_REF="${2}"

echo "➡️   Signing Docker image..."
cosign sign -y --key "${KEY_REF}" "${IMAGE_REF}"
