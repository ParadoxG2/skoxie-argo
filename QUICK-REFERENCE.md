# Quick Reference Guide

## One-Line Commands

### Deployment
```bash
# Deploy everything
kubectl apply -f root-app.yaml

# Sync all applications
argocd app sync --all

# Sync specific app
argocd app sync <app-name>
```

### Monitoring
```bash
# Watch all applications
kubectl get applications -n argocd -w

# Get all application status
kubectl get applications -n argocd

# Check pods in all namespaces
kubectl get pods -A | grep -E "traefik|cert-manager|cloudflare|pangolin"

# Watch certificates
kubectl get certificates -A -w
```

### Troubleshooting
```bash
# Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f

# cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Cloudflare DDNS logs
kubectl logs -n cloudflare-ddns -l app=cloudflare-ddns -f

# Pangolin logs
kubectl logs -n pangolin -l app=pangolin -f

# Check certificate status
kubectl describe certificate woxie-xyz-wildcard -n traefik

# Get LoadBalancer IP
kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Secrets Management
```bash
# View secret (base64 decoded)
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.apiToken}' | base64 -d

# Update secret
kubectl create secret generic <secret-name> -n <namespace> \
  --from-literal=key=value \
  --dry-run=client -o yaml | kubectl apply -f -

# Delete and recreate secret
kubectl delete secret <secret-name> -n <namespace>
kubectl apply -f infrastructure/<component>/secret.yaml
```

## Quick Fixes

### Certificate Not Issuing
```bash
# Check cert-manager
kubectl get pods -n cert-manager
kubectl logs -n cert-manager -l app=cert-manager -f

# Delete and recreate certificate
kubectl delete certificate woxie-xyz-wildcard -n traefik
kubectl apply -f infrastructure/cert-manager/wildcard-certificate.yaml

# Check challenge status
kubectl get challenges -A
```

### Traefik Not Working
```bash
# Restart Traefik
kubectl rollout restart deployment -n traefik

# Check Traefik service
kubectl get svc -n traefik

# Check IngressRoutes
kubectl get ingressroute -A
```

### DDNS Not Updating
```bash
# Restart DDNS
kubectl rollout restart deployment cloudflare-ddns -n cloudflare-ddns
kubectl rollout restart deployment cloudflare-ddns-wildcard -n cloudflare-ddns

# Check current IP
kubectl exec -n cloudflare-ddns deployment/cloudflare-ddns -- curl -s https://api.ipify.org
```

### ArgoCD App Out of Sync
```bash
# Force sync
argocd app sync <app-name> --force

# Refresh app
argocd app get <app-name> --refresh

# Hard refresh
argocd app get <app-name> --hard-refresh
```

## Component URLs

After DNS propagates:
- Traefik: https://traefik.woxie.xyz
- Whoami: https://whoami.woxie.xyz
- Hello: https://hello.woxie.xyz
- Auth: https://auth.woxie.xyz
- ArgoCD: https://argocd.woxie.xyz (after configuring ingress)

## Important Files

### Secrets
- `infrastructure/traefik/cloudflare-secret.yaml` - Traefik Cloudflare credentials
- `infrastructure/cert-manager/cloudflare-secret.yaml` - cert-manager Cloudflare credentials
- `infrastructure/cloudflare-ddns/secret.yaml` - DDNS Cloudflare credentials
- `infrastructure/pangolin/secret.yaml` - Authentication secrets

### Configuration
- `config/values.yaml` - Global configuration
- `root-app.yaml` - Root ArgoCD application
- `bootstrap/*.yaml` - Component applications

### Infrastructure
- `infrastructure/traefik/` - Ingress controller
- `infrastructure/cert-manager/` - Certificate management
- `infrastructure/cloudflare-ddns/` - DDNS updater
- `infrastructure/pangolin/` - Authentication

## Environment Variables

When using scripts:
```bash
export KUBECONFIG=/path/to/kubeconfig
export ARGOCD_SERVER=argocd.woxie.xyz
export ARGOCD_AUTH_TOKEN=<token>
```

## Useful kubectl Plugins

```bash
# Install krew (kubectl plugin manager)
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# Useful plugins
kubectl krew install ctx        # Switch contexts
kubectl krew install ns         # Switch namespaces
kubectl krew install tree       # Show resource tree
kubectl krew install status     # Better status view
```

## Common Issues

### Issue: DNS not resolving
**Fix**: Wait 5-10 minutes for DDNS to update. Check Cloudflare dashboard.

### Issue: Certificate pending
**Fix**: Check cert-manager logs. Verify API token permissions. Use staging issuer first.

### Issue: Application not syncing
**Fix**: Check ArgoCD logs. Verify repository URL. Force sync.

### Issue: Traefik dashboard not accessible
**Fix**: Check IngressRoute. Verify certificate. Check Traefik logs.

### Issue: Out of sync after changes
**Fix**: Commit and push changes. Wait for ArgoCD to sync or force sync.

## Best Practices

1. **Always use staging certificates first** to avoid rate limits
2. **Commit changes to Git** - ArgoCD deploys from Git
3. **Check logs** before asking for help
4. **Use namespaces** to organize applications
5. **Label everything** for easy filtering
6. **Document changes** in commit messages
7. **Test in staging** before production
8. **Monitor certificate expiration**
9. **Keep secrets secure** - consider Sealed Secrets
10. **Regular updates** - keep components up to date

## Getting Help

- **ArgoCD Docs**: https://argo-cd.readthedocs.io/
- **Traefik Docs**: https://doc.traefik.io/traefik/
- **cert-manager Docs**: https://cert-manager.io/docs/
- **Cloudflare API Docs**: https://developers.cloudflare.com/api/
- **Kubernetes Docs**: https://kubernetes.io/docs/

## Emergency Commands

```bash
# Delete everything (USE WITH CAUTION!)
kubectl delete application root-app -n argocd

# Restart everything
kubectl rollout restart deployment -n traefik
kubectl rollout restart deployment -n cert-manager
kubectl rollout restart deployment -n cloudflare-ddns
kubectl rollout restart deployment -n pangolin

# Force delete stuck resources
kubectl delete <resource> <name> -n <namespace> --grace-period=0 --force

# Get all resources in namespace
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
```
