#!/usr/bin/env bash
set -euo pipefail

# This taken from FluxCD documentation examples
# Validates Flux custom resources and kustomize overlays using kubeconform.
# Prerequisites: yq v4.48+, kustomize v5.7+, kubeconform v0.7+

kustomize_flags=("--load-restrictor=LoadRestrictionsNone")
kubeconform_flags=("-skip=Secret")
kubeconform_config=("-strict" "-ignore-missing-schemas" "-schema-location" "default" "-schema-location" "/tmp/flux-crd-schemas" "-verbose")

echo "Downloading Flux OpenAPI schemas..."
mkdir -p /tmp/flux-crd-schemas/master-standalone-strict
curl -sL https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-crd-schemas/master-standalone-strict

echo "Validating YAML syntax..."
find . -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file; do
  yq e 'true' "$file" > /dev/null
done

echo "Validating cluster manifests..."
find ./clusters -maxdepth 2 -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file; do
  kubeconform "${kubeconform_flags[@]}" "${kubeconform_config[@]}" "${file}"
done

echo "Validating kustomize overlays..."
find . -type f -name 'kustomization.yaml' -print0 | while IFS= read -r -d $'\0' file; do
  dir="${file%kustomization.yaml}"
  echo "  ${dir:-./}"
  kustomize build "${dir}" "${kustomize_flags[@]}" | kubeconform "${kubeconform_flags[@]}" "${kubeconform_config[@]}"
done

echo "Validation complete."
