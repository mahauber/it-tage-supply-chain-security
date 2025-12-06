#!/bin/bash
set -euo pipefail

# Default values
VERSION="v3.0.2"

# Usage function
usage() {
  cat <<EOF
Usage: $0 [--version VERSION]

Install Cosign for container signing.

Optional arguments:
  --version VERSION    Cosign version to install (default: v3.0.2)
  --help               Show this help message

Example:
  $0 --version v3.0.2
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --version)
      VERSION="$2"
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

# Validate version format
if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Invalid version format: ${VERSION}" >&2
  echo "Expected format: v3.0.2" >&2
  exit 1
fi

echo "➡️   Installing Cosign ${VERSION}..."
curl -sLO "https://github.com/sigstore/cosign/releases/download/${VERSION}/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign
cosign version
echo "✅ Successfully installed Cosign ${VERSION}"
