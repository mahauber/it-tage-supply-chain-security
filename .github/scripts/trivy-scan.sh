#!/bin/bash
set -euo pipefail

# Default values
IMAGE_REF=""
SEVERITY="CRITICAL,HIGH"
EXIT_CODE="1"

# Usage function
usage() {
  cat <<EOF
Usage: $0 --image IMAGE_REF [--severity SEVERITY] [--exit-code CODE]

Scan container image for vulnerabilities using Trivy.

Required arguments:
  --image IMAGE_REF        Container image reference to scan

Optional arguments:
  --severity SEVERITY      Comma-separated list of severities (default: CRITICAL,HIGH)
                          Options: CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN
  --exit-code CODE         Exit code when vulnerabilities found (default: 1, use 0 to not fail)
  --help                   Show this help message

Example:
  $0 --image myregistry.azurecr.io/app:latest --severity CRITICAL,HIGH
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --image)
      IMAGE_REF="$2"
      shift 2
      ;;
    --severity)
      SEVERITY="$2"
      shift 2
      ;;
    --exit-code)
      EXIT_CODE="$2"
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
if [[ -z "${IMAGE_REF}" ]]; then
  echo "ERROR: Image reference is required (--image flag)" >&2
  usage
fi

# Validate severity format
if [[ ! "${SEVERITY}" =~ ^(CRITICAL|HIGH|MEDIUM|LOW|UNKNOWN)(,(CRITICAL|HIGH|MEDIUM|LOW|UNKNOWN))*$ ]]; then
  echo "ERROR: Invalid severity format: ${SEVERITY}" >&2
  echo "Expected format: CRITICAL,HIGH or MEDIUM,LOW,UNKNOWN" >&2
  exit 1
fi

# Validate exit code
if [[ ! "${EXIT_CODE}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Invalid exit code: ${EXIT_CODE}" >&2
  exit 1
fi

echo "➡️   Scanning image for vulnerabilities..."
echo "    Image: ${IMAGE_REF}"
echo "    Severity: ${SEVERITY}"

trivy image --severity "${SEVERITY}" --exit-code "${EXIT_CODE}" --no-progress "${IMAGE_REF}"

if [[ "${EXIT_CODE}" == "0" ]] || [[ $? -eq 0 ]]; then
  echo "✅ Vulnerability scan completed"
fi
