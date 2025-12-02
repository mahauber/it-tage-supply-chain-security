#!/bin/bash
set -e

REGISTRY="${1:-ghcr.io}"
USERNAME="${2}"
PASSWORD="${3}"

echo "➡️   Logging in to ${REGISTRY}..."
echo "${PASSWORD}" | docker login "${REGISTRY}" -u "${USERNAME}" --password-stdin
