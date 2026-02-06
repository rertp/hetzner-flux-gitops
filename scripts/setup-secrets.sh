#!/bin/bash
set -e

# Configuration
KEY_FILE="private.key"
CERT_FILE="pub-sealed-secrets.pem"
NAMESPACE="sealed-secrets"
SECRET_NAME="sealed-secrets-key"

# Check if files exist
if [[ ! -f "$KEY_FILE" ]]; then
    echo "Error: $KEY_FILE not found in current directory."
    echo "Please verify the key file is present."
    exit 1
fi

if [[ ! -f "$CERT_FILE" ]]; then
    echo "Error: $CERT_FILE not found in current directory."
    echo "Please verify the certificate file is present."
    exit 1
fi

echo "Setting up Sealed Secrets..."

# Create namespace
echo -e "\nCreating namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create secret
echo -e "\nCreating sealed-secrets key..."

if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    echo "Secret $SECRET_NAME already exists. Replacing..."
    kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
fi

kubectl create secret tls "$SECRET_NAME" \
  --cert="$CERT_FILE" \
  --key="$KEY_FILE" \
  --namespace="$NAMESPACE"

# Label secret
echo -e "\nLabeling secret as active..."

kubectl label secret "$SECRET_NAME" \
  -n "$NAMESPACE" \
  sealedsecrets.bitnami.com/sealed-secrets-key=active \
  --overwrite

echo "Sealed Secrets key setup complete!"
