#!/bin/bash
set -e

# Load .env
if [[ -f .env ]]; then
    source .env
else
    echo "Error: .env file not found."
    exit 1
fi

# Ensure offline sealer exists
SCRIPT_DIR=$(dirname "$0")
SEAL_SCRIPT="$SCRIPT_DIR/seal-offline.sh"

if [[ ! -f "$SEAL_SCRIPT" ]]; then
    echo "Error: $SEAL_SCRIPT not found."
    exit 1
fi

echo "Generating Sealed Secrets..."

# 1. Cloudflare API Token (Cert Manager)
echo "-> Sealing cloudflare-api-token (cert-manager)..."
kubectl create secret generic cloudflare-api-token \
    --namespace=cert-manager \
    --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
    --dry-run=client -o yaml | \
    "$SEAL_SCRIPT" > infrastructure/configs/secrets/cloudflare-cert-manager.yaml

# 2. Cloudflare API Token (External DNS)
echo "-> Sealing cloudflare-api-token (external-dns)..."
kubectl create secret generic cloudflare-api-token \
    --namespace=external-dns \
    --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
    --dry-run=client -o yaml | \
    "$SEAL_SCRIPT" > infrastructure/configs/secrets/cloudflare-external-dns.yaml

# 3. R2 Credentials (CNPG)
echo "-> Sealing s3-credentials (databases)..."
kubectl create secret generic s3-credentials \
    --namespace=databases \
    --from-literal=S3_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID" \
    --from-literal=S3_ACCESS_KEY_SECRET="$S3_ACCESS_KEY_SECRET" \
    --dry-run=client -o yaml | \
    "$SEAL_SCRIPT" > infrastructure/configs/secrets/r2-cnpg-backup.yaml

# 4. Infisical Auth
echo "-> Sealing infisical-auth (infisical-operator)..."
kubectl create secret generic infisical-auth \
    --namespace=infisical-operator \
    --from-literal=clientId="$INFISICAL_CLIENT_ID" \
    --from-literal=clientSecret="$INFISICAL_CLIENT_SECRET" \
    --dry-run=client -o yaml | \
    "$SEAL_SCRIPT" > infrastructure/configs/secrets/infisical-auth.yaml

echo "Done!"
