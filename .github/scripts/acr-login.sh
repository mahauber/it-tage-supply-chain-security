#!/bin/bash
set -euo pipefail

# Default values
REGISTRY=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --registry REGISTRY

Login to Azure Container Registry using Azure CLI.

Required arguments:
  --registry REGISTRY    ACR registry URL (e.g., myregistry.azurecr.io)
  --help                 Show this help message

Example:
  $0 --registry myregistry.azurecr.io
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --registry)
      REGISTRY="$2"
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
if [[ -z "${REGISTRY}" ]]; then
  echo "ERROR: Registry is required (--registry flag)" >&2
  usage
fi

# Validate registry format
if [[ ! "${REGISTRY}" =~ ^[a-zA-Z0-9]+\.azurecr\.io$ ]]; then
  echo "ERROR: Invalid ACR registry format: ${REGISTRY}" >&2
  echo "Expected format: myregistry.azurecr.io" >&2
  exit 1
fi

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
  echo "ERROR: Azure CLI (az) is not installed" >&2
  exit 1
fi

echo "➡️   Logging in to ${REGISTRY}..."

# Extract ACR name and login
ACR_NAME="${REGISTRY%%.azurecr.io}"
az acr login --name "${ACR_NAME}"

echo "✅ Successfully logged in to ${REGISTRY}"
