# Setup Guide for Skoxie ArgoCD

This guide will walk you through setting up the complete infrastructure for woxie.xyz.

## Prerequisites Checklist

- [ ] Kubernetes cluster running (v1.24+)
- [ ] kubectl installed and configured
- [ ] Cloudflare account with woxie.xyz domain
- [ ] Cloudflare API token created
- [ ] (Optional) OAuth provider configured for authentication

## Step-by-Step Setup

### Step 1: Install ArgoCD

If ArgoCD is not already installed:

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Step 2: Create Cloudflare API Token

1. Log in to Cloudflare Dashboard
2. Go to My Profile → API Tokens
3. Click "Create Token"
4. Use "Edit zone DNS" template or create custom token with:
   - Permissions: Zone - DNS - Edit, Zone - Zone - Read
   - Zone Resources: Include - Specific zone - woxie.xyz
5. Copy the token (you won't see it again!)

### Step 3: Configure Secrets

Create a temporary file with your credentials (DO NOT COMMIT THIS):

```bash
# Create a temporary env file
cat > /tmp/secrets.env << EOF
CLOUDFLARE_API_TOKEN=your_actual_token_here
CLOUDFLARE_EMAIL=your_email@example.com
LETSENCRYPT_EMAIL=your_email@example.com
PANGOLIN_SESSION_SECRET=$(openssl rand -base64 32)
EOF
```

Now update all secret files:

```bash
# Source the secrets
source /tmp/secrets.env

# Update Traefik secret
sed -i "s/YOUR_EMAIL@example.com/$CLOUDFLARE_EMAIL/g" infrastructure/traefik/cloudflare-secret.yaml
sed -i "s/YOUR_CLOUDFLARE_API_TOKEN/$CLOUDFLARE_API_TOKEN/g" infrastructure/traefik/cloudflare-secret.yaml

# Update cert-manager secret
sed -i "s/YOUR_CLOUDFLARE_API_TOKEN/$CLOUDFLARE_API_TOKEN/g" infrastructure/cert-manager/cloudflare-secret.yaml
sed -i "s/YOUR_EMAIL@example.com/$LETSENCRYPT_EMAIL/g" infrastructure/cert-manager/cluster-issuer-production.yaml
sed -i "s/YOUR_EMAIL@example.com/$LETSENCRYPT_EMAIL/g" infrastructure/cert-manager/cluster-issuer-staging.yaml

# Update Cloudflare DDNS secret
sed -i "s/YOUR_CLOUDFLARE_API_TOKEN/$CLOUDFLARE_API_TOKEN/g" infrastructure/cloudflare-ddns/secret.yaml

# Update Pangolin secret
sed -i "s/CHANGE_THIS_TO_A_SECURE_RANDOM_STRING/$PANGOLIN_SESSION_SECRET/g" infrastructure/pangolin/secret.yaml

# Update config values
sed -i "s/YOUR_CLOUDFLARE_API_TOKEN/$CLOUDFLARE_API_TOKEN/g" config/values.yaml
sed -i "s/YOUR_EMAIL@example.com/$CLOUDFLARE_EMAIL/g" config/values.yaml

# Clean up
shred -u /tmp/secrets.env
```

### Step 4: Deploy Root Application

```bash
# Apply the root application
kubectl apply -f root-app.yaml

# Watch the deployment
watch kubectl get applications -n argocd
```

Wait for all applications to show "Synced" and "Healthy" status.

### Step 5: Verify Installation

```bash
# Check all namespaces
kubectl get namespaces | grep -E "traefik|cert-manager|cloudflare|pangolin"

# Check Traefik
kubectl get pods -n traefik
kubectl get svc -n traefik

# Check cert-manager
kubectl get pods -n cert-manager

# Check certificates
kubectl get certificates -A

# Check Cloudflare DDNS
kubectl get pods -n cloudflare-ddns

# Check Pangolin
kubectl get pods -n pangolin
```

### Step 6: Configure DNS (If Not Using DDNS)

If you have a static IP and prefer manual DNS configuration:

1. Get your LoadBalancer IP:
```bash
kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

2. In Cloudflare, create A records:
   - `woxie.xyz` → Your IP
   - `*.woxie.xyz` → Your IP

### Step 7: Wait for Certificates

```bash
# Watch certificate status
watch kubectl get certificates -A

# Check cert-manager logs if issues
kubectl logs -n cert-manager -l app=cert-manager -f
```

Certificates can take 2-5 minutes to issue.

### Step 8: Access Services

Once certificates are ready:

- Traefik Dashboard: https://traefik.woxie.xyz
- Whoami Demo: https://whoami.woxie.xyz
- Hello World Demo: https://hello.woxie.xyz
- Pangolin Auth: https://auth.woxie.xyz

### Step 9: Setup ArgoCD Ingress (Optional)

Create `infrastructure/argocd-ingress.yaml`:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: argocd-server
  namespace: argocd
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`argocd.woxie.xyz`)
      kind: Rule
      services:
        - name: argocd-server
          port: 80
  tls:
    certResolver: cloudflare
```

Apply it:
```bash
kubectl apply -f infrastructure/argocd-ingress.yaml
```

Access ArgoCD at: https://argocd.woxie.xyz

## Troubleshooting

### Issue: Certificates Not Issuing

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Check certificate details
kubectl describe certificate woxie-xyz-wildcard -n traefik

# Common issues:
# 1. Wrong API token - verify in Cloudflare secret
# 2. API token permissions - needs DNS Edit + Zone Read
# 3. Rate limiting - use staging issuer first
```

### Issue: DDNS Not Updating

```bash
# Check DDNS logs
kubectl logs -n cloudflare-ddns -l app=cloudflare-ddns -f

# Verify secret
kubectl get secret cloudflare-ddns-secret -n cloudflare-ddns -o yaml

# Check if IP is detected
kubectl exec -n cloudflare-ddns deployment/cloudflare-ddns -- curl -s https://api.ipify.org
```

### Issue: Traefik Not Starting

```bash
# Check Traefik pods
kubectl get pods -n traefik

# Check logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f

# Common issues:
# 1. Port conflicts
# 2. Missing secrets
# 3. Invalid configuration
```

### Issue: Applications Not Syncing

```bash
# Check ArgoCD application
argocd app get <app-name>

# Force sync
argocd app sync <app-name>

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f
```

## Advanced Configuration

### Using Staging Certificates (Recommended for Testing)

Edit certificate to use staging:
```bash
kubectl edit certificate woxie-xyz-wildcard -n traefik
# Change issuerRef.name to: letsencrypt-staging
```

### Adding OAuth to Pangolin

1. Configure OAuth provider (Google, GitHub, etc.)
2. Update `infrastructure/pangolin/secret.yaml` with client ID/secret
3. Update `infrastructure/pangolin/deployment.yaml` with provider URLs
4. Redeploy: `argocd app sync pangolin`

### Monitoring Setup

Add Prometheus and Grafana:
```bash
# Add to apps/ directory
# Create monitoring-app.yaml with Prometheus/Grafana
```

## Next Steps

1. ✅ Verify all applications are healthy
2. ✅ Test accessing demo applications
3. ✅ Configure Pangolin OAuth (if needed)
4. ✅ Add your own applications
5. ✅ Set up monitoring and alerting
6. ✅ Configure backup strategy

## Security Best Practices

1. **Secrets Management**: Consider using Sealed Secrets or External Secrets Operator
2. **RBAC**: Configure proper RBAC for ArgoCD
3. **Network Policies**: Add network policies to restrict traffic
4. **Authentication**: Enable Pangolin for all sensitive apps
5. **Updates**: Regularly update all components
6. **Monitoring**: Set up alerts for certificate expiration

## Getting Help

- Check logs: `kubectl logs -n <namespace> <pod-name>`
- ArgoCD UI: Visual overview of applications
- Community: ArgoCD Slack, GitHub issues

---

Happy GitOps! 🚀
