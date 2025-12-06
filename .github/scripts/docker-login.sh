#!/bin/bash
set -euo pipefail

# Default values
REGISTRY=""
AUTH_METHOD="oidc"  # oidc or password
REGISTRY_TYPE="acr"  # acr or docker
USERNAME=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --registry REGISTRY [--auth-method METHOD] [--username USERNAME] [--type TYPE]

Login to a container registry.

Required arguments:
  --registry REGISTRY        Registry URL (e.g., myregistry.azurecr.io or ghcr.io)

Optional arguments:
  --auth-method METHOD       Authentication method: 'oidc' or 'password' (default: oidc)
  --username USERNAME        Username for password authentication (required if auth-method=password)
  --type TYPE                Registry type: 'acr' or 'docker' (default: acr)
  --help                     Show this help message

Environment variables (for password auth):
  DOCKER_PASSWORD            Password or token for authentication (required if auth-method=password)

Example (OIDC):
  $0 --registry myregistry.azurecr.io --auth-method oidc --type acr

Example (Password):
  DOCKER_PASSWORD=\$TOKEN $0 --registry myregistry.azurecr.io --auth-method password --username myuser --type acr
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
    --auth-method)
      AUTH_METHOD="$2"
      shift 2
      ;;
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --type)
      REGISTRY_TYPE="$2"
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

# Validate auth method
if [[ "${AUTH_METHOD}" != "oidc" && "${AUTH_METHOD}" != "password" ]]; then
  echo "ERROR: Invalid auth method: ${AUTH_METHOD}. Must be 'oidc' or 'password'" >&2
  exit 1
fi

# Validate registry type
if [[ "${REGISTRY_TYPE}" != "acr" && "${REGISTRY_TYPE}" != "docker" ]]; then
  echo "ERROR: Invalid registry type: ${REGISTRY_TYPE}. Must be 'acr' or 'docker'" >&2
  exit 1
fi

# Validate registry format
if [[ ! "${REGISTRY}" =~ ^[a-zA-Z0-9.-]+\.[a-z]{2,}$ ]]; then
  echo "ERROR: Invalid registry format: ${REGISTRY}" >&2
  echo "Expected format: registry.example.com or myregistry.azurecr.io" >&2
  exit 1
fi

echo "➡️   Logging in to ${REGISTRY} (${REGISTRY_TYPE}, ${AUTH_METHOD})..."

if [[ "${AUTH_METHOD}" == "oidc" ]]; then
  # OIDC authentication (Azure)
  if [[ "${REGISTRY_TYPE}" != "acr" ]]; then
    echo "ERROR: OIDC authentication is only supported for ACR" >&2
    exit 1
  fi
  
  # Check if az CLI is installed
  if ! command -v az &> /dev/null; then
    echo "ERROR: Azure CLI (az) is not installed. Required for OIDC authentication." >&2
    exit 1
  fi
  
  # Login to Azure using OIDC (assumes Azure CLI is already configured with federated credentials)
  echo "🔐 Authenticating with Azure via OIDC..."
  az login --service-principal \
    -u "${ARM_CLIENT_ID}" \
    -t "${ARM_TENANT_ID}" \
    --federated-token "$(cat "${AZURE_FEDERATED_TOKEN_FILE}")" \
    --output none
  
  # Get ACR access token
  echo "🔑 Getting ACR access token..."
  ACR_NAME="${REGISTRY%%.azurecr.io}"
  ACCESS_TOKEN=$(az acr login --name "${ACR_NAME}" --expose-token --output tsv --query accessToken)
  
  # Login to Docker with the token
  echo "${ACCESS_TOKEN}" | docker login "${REGISTRY}" -u 00000000-0000-0000-0000-000000000000 --password-stdin
  
else
  # Password authentication
  if [[ -z "${USERNAME}" ]]; then
    echo "ERROR: Username is required for password authentication (--username flag)" >&2
    usage
  fi
  
  if [[ -z "${DOCKER_PASSWORD:-}" ]]; then
    echo "ERROR: DOCKER_PASSWORD environment variable not set" >&2
    exit 1
  fi
  
  echo "${DOCKER_PASSWORD}" | docker login "${REGISTRY}" -u "${USERNAME}" --password-stdin
fi

echo "✅ Successfully logged in to ${REGISTRY}"
