#!/bin/bash
set -euo pipefail

# Default values
RESOURCE_GROUP=""
CLUSTER_NAME=""
IMAGE_REF=""
KUSTOMIZE_PATH=""
GIT_COMMIT=""
GH_RUN_URL=""

# Usage function
usage() {
  cat <<EOF
Usage: $0 --resource-group RG --cluster-name CLUSTER --image IMAGE --kustomize-path PATH [--git-commit COMMIT] [--run-url URL]

Deploy application to AKS cluster using Kustomize.

Required arguments:
  --resource-group RG      Azure resource group name
  --cluster-name CLUSTER   AKS cluster name
  --image IMAGE            Container image reference with digest
  --kustomize-path PATH    Path to Kustomize overlay directory

Optional arguments:
  --git-commit COMMIT      Git commit SHA for annotation
  --run-url URL            GitHub Actions run URL for annotation
  --help                   Show this help message

Example:
  $0 --resource-group myRG --cluster-name myAKS --image app@sha256:abc --kustomize-path ./k8s/overlays/dev
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    --image)
      IMAGE_REF="$2"
      shift 2
      ;;
    --kustomize-path)
      KUSTOMIZE_PATH="$2"
      shift 2
      ;;
    --git-commit)
      GIT_COMMIT="$2"
      shift 2
      ;;
    --run-url)
      GH_RUN_URL="$2"
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
if [[ -z "${RESOURCE_GROUP}" ]]; then
  echo "ERROR: Resource group is required (--resource-group flag)" >&2
  usage
fi

if [[ -z "${CLUSTER_NAME}" ]]; then
  echo "ERROR: Cluster name is required (--cluster-name flag)" >&2
  usage
fi

if [[ -z "${IMAGE_REF}" ]]; then
  echo "ERROR: Image reference is required (--image flag)" >&2
  usage
fi

if [[ -z "${KUSTOMIZE_PATH}" ]]; then
  echo "ERROR: Kustomize path is required (--kustomize-path flag)" >&2
  usage
fi

# Validate kustomize path exists
if [[ ! -d "${KUSTOMIZE_PATH}" ]]; then
  echo "ERROR: Kustomize path does not exist: ${KUSTOMIZE_PATH}" >&2
  exit 1
fi

# Validate kustomization.yaml exists
if [[ ! -f "${KUSTOMIZE_PATH}/kustomization.yaml" ]] && [[ ! -f "${KUSTOMIZE_PATH}/kustomization.yml" ]]; then
  echo "ERROR: kustomization.yaml not found in: ${KUSTOMIZE_PATH}" >&2
  exit 1
fi

# Check required tools
for tool in az kubectl kustomize kubelogin; do
  if ! command -v "${tool}" &> /dev/null; then
    echo "ERROR: Required tool '${tool}' is not installed" >&2
    exit 1
  fi
done

echo "➡️   Connecting to AKS cluster..."
echo "    Resource Group: ${RESOURCE_GROUP}"
echo "    Cluster: ${CLUSTER_NAME}"

az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

echo "➡️   Setting new image version in kustomization..."
echo "    Image: ${IMAGE_REF}"
echo "    Kustomize Path: ${KUSTOMIZE_PATH}"

cd "${KUSTOMIZE_PATH}"
kustomize edit set image "${IMAGE_REF}"

if [[ -n "${GIT_COMMIT}" ]] && [[ -n "${GH_RUN_URL}" ]]; then
  kustomize edit set annotation "git-commit:${GIT_COMMIT}" "gh-actions-run:${GH_RUN_URL}"
fi

echo "➡️   Applying Kustomize..."
kubectl apply -k .

echo "✅ Successfully deployed to AKS cluster: ${CLUSTER_NAME}"
