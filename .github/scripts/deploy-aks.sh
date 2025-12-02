#!/bin/bash
set -e

RESOURCE_GROUP="${1}"
CLUSTER_NAME="${2}"
IMAGE_REF="${3}"
KUSTOMIZE_PATH="${4}"
GIT_COMMIT="${5}"
GH_RUN_URL="${6}"

echo "➡️   Connecting to AKS cluster..."
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

echo "➡️   Setting new image version in kustomization..."
cd "${KUSTOMIZE_PATH}"
kustomize edit set image "${IMAGE_REF}"
kustomize edit set annotation "git-commit:${GIT_COMMIT}" "gh-actions-run:${GH_RUN_URL}"

echo "➡️   Applying Kustomize..."
kubectl apply -k .
