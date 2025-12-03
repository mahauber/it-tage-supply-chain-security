#!/bin/bash

helm repo add traefik https://traefik.github.io/charts
helm upgrade --install traefik traefik/traefik \
    --version 37.4.0 \
    -f traefik/values.yaml \
    --create-namespace \
    --namespace traefik