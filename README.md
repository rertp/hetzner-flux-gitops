# GitOps

FluxCD-managed Kubernetes infrastructure for Hetzner Cloud.

> [!IMPORTANT]
> This repository is a **complementary** GitOps repo for the Pulumi-managed cluster created using [muhammadnawzad/talos-hetzner-cluster](https://github.com/muhammadnawzad/talos-hetzner-cluster).
> Both projects are designed to work together, as there are specific assumptions made in this repository based on the Pulumi cluster configuration. While this repo can be used independently with modifications, exercise caution when doing so.
>
> [!WARNING]
> Please review all configurations thoroughly. This is one of my very first DevOps projects, and I am a hobbyist, not an expert. Everything here should be taken with a grain of salt and verified for your specific use case.

## Crucial Placeholder Updates

Before bootstrapping Flux, you **must** review the codebase and update placeholders. At a minimum, search and replace the following:

- `example@mail.com`: Your email for Let's Encrypt certificates (check `cluster-issuers.yaml`).
- `domain-example`: Your domain name prefix (check `external-dns.yaml` and various ingresses).
- `domain-example.com`: Your full domain name.
- `<s3-endpoint-url>`: Your S3-compatible storage endpoint for backups (check `cluster.yaml`).

> [!TIP]
> Perform a global search for "example" and "domain" to ensure all placeholders are adjusted to your environment.

## Repository Structure

```text
├── clusters/dev/           # Cluster entrypoint
│   ├── flux-system/        # Flux components
│   ├── infrastructure.yaml # Infrastructure kustomizations
│   └── apps.yaml           # Application kustomizations
├── infrastructure/
│   ├── controllers/        # Platform operators
│   ├── configs/            # Cluster configuration
│   └── data/               # Stateful services (PostgreSQL)
└── apps/
    ├── base/               # Application definitions
    │   ├── backend/        # Backend services
    │   ├── frontend/       # Frontend services
    │   └── fullstack/      # Full-stack applications
    └── dev/                # Environment overlay
```

## Prerequisites

- Kubernetes cluster with Cilium CNI
- [Flux CLI](https://fluxcd.io/flux/installation/)
- [kubeseal CLI](https://github.com/bitnami-labs/sealed-secrets)
- GitHub PAT with repo permissions

## Setup Guide

Follow these steps to bootstrap the cluster with all secrets correctly configured.

### 1. Prepare Master Keys

You must provide the Sealed Secrets master key to ensure you can encrypt/decrypt secrets consistently.

1. Obtain your `private.key` and `pub-sealed-secrets.pem` (e.g., from a backup of your previous cluster).
2. Place them in the root of this repository. **They are gitignored and will not be committed.**

### 2. Configure Cluster Master Key

Apply the master key to the cluster so the Sealed Secrets controller can decrypt your secrets.

```bash
chmod +x scripts/setup-secrets.sh
./scripts/setup-secrets.sh
```

### 3. Generate Service Secrets

Generate all the application and infrastructure secrets (like Cloudflare tokens) using your local `.env` values and the public key.

1. Copy `.env.example` to `.env` (if you haven't) and fill in your actual values.
2. Run the generation script:

```bash
chmod +x scripts/generate-sealed-secrets.sh
./scripts/generate-sealed-secrets.sh
```

This will update all YAML files in `infrastructure/configs/secrets/` with fresh encrypted data.

### 4. Bootstrap Flux

Now that secrets are staged and the master key is in the cluster, bootstrap Flux:

```bash
export GITHUB_TOKEN="<your-token>"
export GITHUB_USER=""
export GITHUB_REPO=""

flux bootstrap github \
  --token-auth \
  --owner=${GITHUB_USER} \
  --repository=${GITHUB_REPO} \
  --branch=main \
  --path=clusters/dev \
  --personal \
  --components=source-controller,kustomize-controller,helm-controller
```

## Components

### Infrastructure

| Controller         | Description                                    |
|--------------------|------------------------------------------------|
| Traefik            | Ingress controller with Hetzner LB integration |
| cert-manager       | TLS certificates via Let's Encrypt (DNS-01)    |
| external-dns       | Automatic DNS management (Cloudflare)          |
| sealed-secrets     | Encrypted secrets for GitOps                   |
| CloudNativePG      | PostgreSQL operator                            |
| Infisical          | Secrets management operator                    |

### Applications

| App     | Description      |
|---------|------------------|
| podinfo | Demo application |

## Dependency Chain

```text
infra-controllers → infra-secrets → infra-configs → infra-data → apps
```

## Adding Applications

1. Create app directory under `apps/base/<category>/<app-name>/`
2. Add required manifests:
   - `kustomization.yaml`
   - `namespace.yaml`
   - `repository.yaml` (HelmRepository)
   - `release.yaml` (HelmRelease)
   - `ingress.yaml` (optional)
3. Reference in `apps/base/kustomization.yaml`
4. Commit and push

## Validation

The repository can be validated for basic syntax and configuration issues using the script below. This script is from an example from the FluxCD documentation and works reliably.

```bash
./scripts/validate.sh
```

## Troubleshooting

```bash
# Flux status
flux get all -A

# Force reconciliation
flux reconcile kustomization flux-system --with-source

# Logs
flux logs --all-namespaces

# Certificate status
kubectl get certificates,certificaterequests,challenges -A
```

## Contributions

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.
