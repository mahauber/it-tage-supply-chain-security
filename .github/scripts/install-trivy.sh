#!/bin/bash
set -euo pipefail

# Usage function
usage() {
  cat <<EOF
Usage: $0 [--help]

Install Trivy vulnerability scanner.

Optional arguments:
  --help    Show this help message

Example:
  $0
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      usage
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage
      ;;
  esac
done

echo "➡️   Installing Trivy..."

# Check if running on Debian/Ubuntu
if ! command -v apt-get &> /dev/null; then
  echo "ERROR: This script requires apt-get (Debian/Ubuntu)" >&2
  exit 1
fi

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y -qq wget apt-transport-https gnupg lsb-release

# Add Trivy repository
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list

# Install Trivy
sudo apt-get update -qq
sudo apt-get install -y trivy

trivy --version
echo "✅ Successfully installed Trivy"
