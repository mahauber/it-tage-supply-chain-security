#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCRIPTS_DIR="${REPO_ROOT}/.github/scripts"

# Function to print usage
usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Build, scan, sign, and optionally deploy the simple-service container image locally.

OPTIONS:
  -i, --image-name IMAGE      Image name (default: ghcr.io/mahauber/it-tage-supply-chain-security/simple-service:local)
  -r, --registry REGISTRY     Container registry (default: ghcr.io)
  -u, --username USERNAME     Registry username (required for push)
  -p, --password PASSWORD     Registry password (required for push)
  -k, --key-ref KEY_REF       Cosign key reference for signing (optional)
  --skip-push                 Skip pushing image to registry
  --skip-scan                 Skip Trivy vulnerability scan
  --skip-sign                 Skip image and SBOM signing
  --skip-sbom                 Skip SBOM generation
  --deploy                    Deploy to AKS cluster (requires additional env vars)
  --platforms PLATFORMS       Build platforms (default: linux/amd64)
  -h, --help                  Display this help message

EXAMPLES:
  # Build and scan locally (no push)
  $(basename "$0") --skip-push

  # Build, push to registry
  $(basename "$0") -u myuser -p mypassword

  # Full pipeline with signing
  export COSIGN_KEY_REF="azurekms://..."
  $(basename "$0") -u myuser -p mypassword -k "\$COSIGN_KEY_REF"

  # Multi-platform build
  $(basename "$0") --platforms linux/amd64,linux/arm64 --skip-push

ENVIRONMENT VARIABLES (for secrets):
  DOCKER_PASSWORD             Registry password (alternative to -p)
  COSIGN_KEY_REF              Cosign key reference (alternative to -k)
  DEV_AKS_RESOURCE_GROUP      AKS resource group (for --deploy)
  DEV_AKS_CLUSTER_NAME        AKS cluster name (for --deploy)

EOF
  exit 0
}

# Function to print colored messages
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
IMAGE_NAME="ghcr.io/mahauber/it-tage-supply-chain-security/simple-service:local"
REGISTRY="ghcr.io"
USERNAME=""
PASSWORD=""
KEY_REF=""
SKIP_PUSH=false
SKIP_SCAN=false
SKIP_SIGN=false
SKIP_SBOM=false
DEPLOY=false
PLATFORMS="linux/amd64"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -r|--registry)
      REGISTRY="$2"
      shift 2
      ;;
    -u|--username)
      USERNAME="$2"
      shift 2
      ;;
    -p|--password)
      PASSWORD="$2"
      shift 2
      ;;
    -k|--key-ref)
      KEY_REF="$2"
      shift 2
      ;;
    --skip-push)
      SKIP_PUSH=true
      shift
      ;;
    --skip-scan)
      SKIP_SCAN=true
      shift
      ;;
    --skip-sign)
      SKIP_SIGN=true
      shift
      ;;
    --skip-sbom)
      SKIP_SBOM=true
      shift
      ;;
    --deploy)
      DEPLOY=true
      shift
      ;;
    --platforms)
      PLATFORMS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      ;;
  esac
done

# Check for secrets in environment variables
if [[ -n "${DOCKER_PASSWORD:-}" ]]; then
  PASSWORD="${DOCKER_PASSWORD}"
fi

if [[ -n "${COSIGN_KEY_REF:-}" ]]; then
  KEY_REF="${COSIGN_KEY_REF}"
fi

# Validate prerequisites
log_info "Validating prerequisites..."

# Check if we're in the right directory
if [[ ! -d "${REPO_ROOT}/simple-service" ]]; then
  log_error "simple-service directory not found. Are you in the correct repository?"
  exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
  log_error "Docker is not installed"
  exit 1
fi

log_info "Starting build pipeline for: ${IMAGE_NAME}"
echo ""

# Step 1: Install Cosign (if signing is enabled)
if [[ "${SKIP_SIGN}" == "false" ]]; then
  log_info "Step 1/11: Installing Cosign..."
  if ! command -v cosign &> /dev/null; then
    chmod +x "${SCRIPTS_DIR}/install-cosign.sh"
    "${SCRIPTS_DIR}/install-cosign.sh" "v3.0.2"
  else
    log_info "Cosign already installed: $(cosign version 2>&1 | head -n1)"
  fi
else
  log_info "Step 1/11: Skipping Cosign installation (signing disabled)"
fi
echo ""

# Step 2: Set up Docker Buildx
log_info "Step 2/11: Setting up Docker Buildx..."
chmod +x "${SCRIPTS_DIR}/setup-docker-buildx.sh"
"${SCRIPTS_DIR}/setup-docker-buildx.sh"
echo ""

# Step 3: Login to registry (if pushing)
if [[ "${SKIP_PUSH}" == "false" ]]; then
  log_info "Step 3/11: Logging in to container registry..."
  if [[ -z "${USERNAME}" ]] || [[ -z "${PASSWORD}" ]]; then
    log_error "Username and password required for registry login"
    log_error "Use -u/--username and -p/--password or set DOCKER_PASSWORD env var"
    exit 1
  fi
  export DOCKER_PASSWORD="${PASSWORD}"
  chmod +x "${SCRIPTS_DIR}/docker-login.sh"
  "${SCRIPTS_DIR}/docker-login.sh" "${REGISTRY}" "${USERNAME}"
else
  log_info "Step 3/11: Skipping registry login (push disabled)"
fi
echo ""

# Step 4: Build (and optionally push) image
log_info "Step 4/11: Building container image..."
chmod +x "${SCRIPTS_DIR}/build-push-image.sh"
if [[ "${SKIP_PUSH}" == "false" ]]; then
  "${SCRIPTS_DIR}/build-push-image.sh" "${IMAGE_NAME}" "${REPO_ROOT}/simple-service" "${PLATFORMS}"
else
  log_info "Building locally without push..."
  docker buildx build \
    --platform "${PLATFORMS}" \
    --load \
    -t "${IMAGE_NAME}" \
    "${REPO_ROOT}/simple-service"
fi
echo ""

# Step 5: Install Trivy (if scanning is enabled)
if [[ "${SKIP_SCAN}" == "false" ]]; then
  log_info "Step 5/11: Installing Trivy..."
  if ! command -v trivy &> /dev/null; then
    chmod +x "${SCRIPTS_DIR}/install-trivy.sh"
    "${SCRIPTS_DIR}/install-trivy.sh"
  else
    log_info "Trivy already installed: $(trivy --version | head -n1)"
  fi
else
  log_info "Step 5/11: Skipping Trivy installation (scan disabled)"
fi
echo ""

# Step 6: Scan for vulnerabilities
if [[ "${SKIP_SCAN}" == "false" ]]; then
  log_info "Step 6/11: Scanning for vulnerabilities..."
  chmod +x "${SCRIPTS_DIR}/trivy-scan.sh"
  if "${SCRIPTS_DIR}/trivy-scan.sh" "${IMAGE_NAME}"; then
    log_info "No critical or high vulnerabilities found"
  else
    log_warn "Vulnerabilities found! Review the output above."
  fi
else
  log_info "Step 6/11: Skipping vulnerability scan"
fi
echo ""

# Step 7: Get image digest (if pushed)
IMAGE_REF_DIGEST="${IMAGE_NAME}"
if [[ "${SKIP_PUSH}" == "false" ]]; then
  log_info "Step 7/11: Getting image digest..."
  IMAGE_REF_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${IMAGE_NAME}" || echo "${IMAGE_NAME}")
  log_info "Image reference: ${IMAGE_REF_DIGEST}"
else
  log_info "Step 7/11: Skipping digest retrieval (local build only)"
fi
echo ""

# Step 8: Sign image
if [[ "${SKIP_SIGN}" == "false" ]]; then
  log_info "Step 8/11: Signing Docker image..."
  if [[ -z "${KEY_REF}" ]]; then
    log_warn "No key reference provided, skipping signing"
    log_warn "Set COSIGN_KEY_REF env var or use -k/--key-ref option"
  else
    export COSIGN_KEY_REF="${KEY_REF}"
    chmod +x "${SCRIPTS_DIR}/sign-image.sh"
    "${SCRIPTS_DIR}/sign-image.sh" "${IMAGE_REF_DIGEST}"
  fi
else
  log_info "Step 8/11: Skipping image signing"
fi
echo ""

# Step 9: Generate SBOM
if [[ "${SKIP_SBOM}" == "false" ]] && [[ "${SKIP_SCAN}" == "false" ]]; then
  log_info "Step 9/11: Generating SBOM..."
  chmod +x "${SCRIPTS_DIR}/generate-sbom.sh"
  "${SCRIPTS_DIR}/generate-sbom.sh" "${IMAGE_REF_DIGEST}" "simple-service.cdx.json"
  log_info "SBOM saved to: simple-service.cdx.json"
else
  log_info "Step 9/11: Skipping SBOM generation"
fi
echo ""

# Step 10: Sign SBOM
if [[ "${SKIP_SBOM}" == "false" ]] && [[ "${SKIP_SIGN}" == "false" ]] && [[ "${SKIP_SCAN}" == "false" ]]; then
  log_info "Step 10/11: Signing SBOM..."
  if [[ -z "${KEY_REF}" ]]; then
    log_warn "No key reference provided, skipping SBOM signing"
  elif [[ ! -f "simple-service.cdx.json" ]]; then
    log_warn "SBOM file not found, skipping signing"
  else
    export COSIGN_KEY_REF="${KEY_REF}"
    chmod +x "${SCRIPTS_DIR}/sign-sbom.sh"
    "${SCRIPTS_DIR}/sign-sbom.sh" "${IMAGE_REF_DIGEST}" "simple-service.cdx.json"
  fi
else
  log_info "Step 10/11: Skipping SBOM signing"
fi
echo ""

# Step 11: Deploy to AKS (if enabled)
if [[ "${DEPLOY}" == "true" ]]; then
  log_info "Step 11/11: Deploying to AKS cluster..."
  if [[ -z "${DEV_AKS_RESOURCE_GROUP:-}" ]] || [[ -z "${DEV_AKS_CLUSTER_NAME:-}" ]]; then
    log_error "AKS deployment requires DEV_AKS_RESOURCE_GROUP and DEV_AKS_CLUSTER_NAME env vars"
    exit 1
  fi
  chmod +x "${SCRIPTS_DIR}/deploy-aks.sh"
  "${SCRIPTS_DIR}/deploy-aks.sh" \
    "${DEV_AKS_RESOURCE_GROUP}" \
    "${DEV_AKS_CLUSTER_NAME}" \
    "${IMAGE_REF_DIGEST}" \
    "${REPO_ROOT}/k8s/applications/simple-service/overlays/dev" \
    "local-build-$(date +%s)" \
    "local-run"
else
  log_info "Step 11/11: Skipping AKS deployment"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Pipeline completed successfully!"
log_info "Image: ${IMAGE_NAME}"
if [[ "${SKIP_PUSH}" == "false" ]]; then
  log_info "Image digest: ${IMAGE_REF_DIGEST}"
fi
if [[ -f "simple-service.cdx.json" ]]; then
  log_info "SBOM: simple-service.cdx.json"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
