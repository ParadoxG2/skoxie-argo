# Deployment Guide - Quick Reference

## One-Command Deployment

For those who want to get started immediately:

```bash
# Clone repository
git clone https://github.com/ParadoxG2/skoxie-argo.git
cd skoxie-argo

# Configure (interactive)
./configure.sh

# Deploy everything
./deploy.sh
```

## Manual Deployment

### Prerequisites

```bash
# Verify cluster connection
kubectl cluster-info

# Install ArgoCD (if needed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Configuration

Replace the following in these files:
- `YOUR_CLOUDFLARE_API_TOKEN` → Your actual Cloudflare API token
- `YOUR_EMAIL@example.com` → Your email address

Files to update:
1. `config/values.yaml`
2. `infrastructure/traefik/cloudflare-secret.yaml`
3. `infrastructure/cert-manager/cloudflare-secret.yaml`
4. `infrastructure/cert-manager/cluster-issuer-production.yaml`
5. `infrastructure/cert-manager/cluster-issuer-staging.yaml`
6. `infrastructure/cloudflare-ddns/secret.yaml`
7. `infrastructure/pangolin/secret.yaml` (generate random secret)

### Deploy

```bash
# Deploy root application
kubectl apply -f root-app.yaml

# Watch deployment
kubectl get applications -n argocd -w
```

## Verification

```bash
# Check all applications
kubectl get applications -n argocd

# Check all pods
kubectl get pods -A

# Check certificates
kubectl get certificates -A

# Get LoadBalancer IP
kubectl get svc -n traefik traefik
```

## Access Services

After DNS propagates (5-10 minutes):
- https://traefik.woxie.xyz - Traefik Dashboard
- https://whoami.woxie.xyz - Whoami Demo
- https://hello.woxie.xyz - Hello World Demo
- https://auth.woxie.xyz - Pangolin Auth

## Troubleshooting

### Certificates Not Issuing

```bash
kubectl logs -n cert-manager -l app=cert-manager -f
kubectl describe certificate woxie-xyz-wildcard -n traefik
```

### ArgoCD Not Syncing

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
argocd app sync root-app
```

### DDNS Not Updating

```bash
kubectl logs -n cloudflare-ddns -l app=cloudflare-ddns -f
```

## Post-Deployment

1. Access ArgoCD UI
2. Verify all applications are healthy
3. Test demo applications
4. Add your own applications
5. Configure monitoring (optional)

See GETTING-STARTED.md for detailed instructions.
