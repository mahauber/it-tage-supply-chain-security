#!/bin/bash
set -e

echo "➡️   Setting up Docker Buildx..."
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap
