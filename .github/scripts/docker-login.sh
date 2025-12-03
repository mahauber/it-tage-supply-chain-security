#!/bin/bash
set -euo pipefail

# Parameters (non-sensitive data)
REGISTRY="${1:-ghcr.io}"
USERNAME="${2}"

# Secrets via environment variable (not visible in process list)
if [[ -z "${DOCKER_PASSWORD:-}" ]]; then
  echo "ERROR: DOCKER_PASSWORD environment variable not set"
  exit 1
fi

# Input validation
if [[ -z "${USERNAME}" ]]; then
  echo "ERROR: USERNAME parameter required"
  exit 1
fi

echo "➡️   Logging in to ${REGISTRY}..."
echo "${DOCKER_PASSWORD}" | docker login "${REGISTRY}" -u "${USERNAME}" --password-stdin
