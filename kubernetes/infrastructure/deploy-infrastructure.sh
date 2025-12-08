#!/bin/bash

helm repo add traefik https://traefik.github.io/charts
helm upgrade --install traefik traefik/traefik \
    --version 37.4.0 \
    -f traefik/values.yaml \
    --create-namespace \
    --namespace traefik

helm repo add connaisseur https://sse-secure-systems.github.io/connaisseur/charts
helm upgrade --install connaisseur connaisseur/connaisseur \
    --atomic \
    -f connaisseur/values.yaml \
    --version 2.9.0 \
    --create-namespace \
    --namespace connaisseur