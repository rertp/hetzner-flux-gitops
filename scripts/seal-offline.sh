#!/bin/bash
set -e

# This script wraps kubeseal to use the local public key for offline sealing.
# Usage: kubectl create secret ... -o yaml --dry-run=client | ./scripts/seal-offline.sh

CERT_FILE="pub-sealed-secrets.pem"

if [[ ! -f "$CERT_FILE" ]]; then
    echo "Error: $CERT_FILE not found in current directory."
    echo "Please fetch the certificate or ensure it is present."
    exit 1
fi

# Pass specific flags to kubeseal along with the cert
# Defaults to yaml format if not specified, but can be overridden by args
kubeseal --cert "$CERT_FILE" --format=yaml "$@"
