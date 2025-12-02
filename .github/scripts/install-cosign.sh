#!/bin/bash
set -e

echo "➡️   Installing Cosign..."
COSIGN_VERSION="${1:-v3.0.2}"
curl -sLO "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign
cosign version
