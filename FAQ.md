# Frequently Asked Questions (FAQ)

## General Questions

### What is this repository?

This is a production-ready ArgoCD GitOps repository for managing Kubernetes applications. It includes Traefik for ingress, cert-manager for SSL certificates, Cloudflare DDNS for dynamic DNS updates, and Pangolin for authentication.

### Who is this for?

- DevOps engineers setting up Kubernetes infrastructure
- Developers learning GitOps practices
- Anyone wanting a complete, working ArgoCD setup
- Teams managing multiple applications on Kubernetes

### What do I need to use this?

- A Kubernetes cluster (v1.24+)
- A Cloudflare account with a domain (woxie.xyz in this case)
- Basic kubectl knowledge
- ArgoCD installed (or use the provided installation guide)

## Setup Questions

### How do I get started?

1. Clone the repository
2. Run `./configure.sh` to set up your credentials
3. Run `./deploy.sh` to deploy everything
4. Wait for DNS to propagate (5-10 minutes)
5. Access your services

See [SETUP.md](SETUP.md) for detailed instructions.

### Do I need to change the domain?

Yes! If you're not using woxie.xyz, you'll need to:
1. Search and replace `woxie.xyz` with your domain
2. Update Cloudflare credentials
3. Update DNS records

```bash
# Replace domain
find . -type f -name "*.yaml" -exec sed -i 's/woxie\.xyz/yourdomain.com/g' {} \;
```

### Can I use this without Cloudflare?

Partially. You can:
- ✅ Use Traefik
- ✅ Use cert-manager with other DNS providers
- ✅ Use static IP instead of DDNS
- ❌ Can't use Cloudflare-specific DDNS updater

You'll need to modify cert-manager configuration for your DNS provider.

### How much does this cost?

**Free Options:**
- Kubernetes cluster: Free tier on many cloud providers
- Cloudflare: Free plan works fine
- Let's Encrypt: Free SSL certificates
- All software components: Open source and free

**Potential Costs:**
- Kubernetes cluster (if not using free tier)
- Domain name registration (~$10-15/year)
- Cloud resources (LoadBalancer, storage)

## Deployment Questions

### How long does deployment take?

- ArgoCD installation: 2-5 minutes
- Infrastructure deployment: 5-10 minutes
- Certificate issuance: 2-5 minutes
- Total: ~15-20 minutes

### Why are certificates not issuing?

Common reasons:
1. **Wrong API token**: Verify Cloudflare credentials
2. **Insufficient permissions**: Token needs DNS Edit + Zone Read
3. **Rate limiting**: Use staging issuer first
4. **DNS propagation**: Wait 5-10 minutes

Check with:
```bash
kubectl describe certificate woxie-xyz-wildcard -n traefik
kubectl logs -n cert-manager -l app=cert-manager
```

### How do I access ArgoCD UI?

```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Or set up an IngressRoute for https://argocd.woxie.xyz
```

### Applications are not syncing. Why?

1. **Manual sync disabled**: Enable auto-sync in Application spec
2. **Git repository unreachable**: Check network and URL
3. **Invalid manifests**: Check ArgoCD UI for errors
4. **Namespace doesn't exist**: Add CreateNamespace=true to syncOptions

Force sync:
```bash
argocd app sync <app-name>
```

## Configuration Questions

### How do I add my own application?

1. Create manifests in `apps/your-app/`
2. Create Deployment, Service, IngressRoute
3. Commit and push to Git
4. ArgoCD will auto-sync

Example:
```yaml
# apps/myapp/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
# ... rest of deployment

---
# Service and IngressRoute
```

### How do I enable authentication on my app?

Add Pangolin middleware to your IngressRoute:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
spec:
  routes:
    - match: Host(`myapp.woxie.xyz`)
      middlewares:
        - name: pangolin-auth
          namespace: pangolin
      # ... rest of route
```

### Can I use different authentication?

Yes! Replace Pangolin with:
- **OAuth2 Proxy**: For OAuth/OIDC
- **Authelia**: For advanced authentication
- **Basic Auth**: Traefik BasicAuth middleware
- **Custom**: Your own authentication service

### How do I use multiple domains?

1. Add domains to Cloudflare DDNS configuration
2. Create certificates for each domain
3. Update IngressRoutes with new domains
4. Configure DNS records

## Troubleshooting Questions

### DDNS is not updating. What should I do?

```bash
# Check DDNS logs
kubectl logs -n cloudflare-ddns -l app=cloudflare-ddns -f

# Verify API token
kubectl get secret cloudflare-ddns-secret -n cloudflare-ddns -o yaml

# Check if IP is detected
kubectl exec -n cloudflare-ddns deployment/cloudflare-ddns -- curl https://api.ipify.org
```

### Traefik dashboard shows 404. Why?

1. **Certificate not ready**: Wait for cert-manager
2. **IngressRoute not applied**: Check `kubectl get ingressroute -A`
3. **DNS not resolving**: Verify DNS records
4. **Wrong domain**: Check Host match in IngressRoute

### How do I view logs?

```bash
# Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f

# cert-manager
kubectl logs -n cert-manager -l app=cert-manager -f

# Specific pod
kubectl logs -n <namespace> <pod-name> -f

# Previous logs (if pod crashed)
kubectl logs -n <namespace> <pod-name> --previous
```

### How do I restart a component?

```bash
# Restart deployment
kubectl rollout restart deployment <name> -n <namespace>

# Restart all in namespace
kubectl rollout restart deployment -n <namespace>

# Delete pod (will recreate)
kubectl delete pod <pod-name> -n <namespace>
```

## Security Questions

### Are my secrets secure?

**Current setup**: Secrets are in plain YAML files in Git (NOT encrypted).

**For production**, use:
- **Sealed Secrets**: Encrypts secrets for Git storage
- **External Secrets Operator**: Pulls from external secret stores
- **Vault**: HashiCorp Vault integration
- **SOPS**: Encrypt secrets with PGP/KMS

### How do I rotate secrets?

```bash
# Update secret file
vim infrastructure/traefik/cloudflare-secret.yaml

# Apply changes
kubectl apply -f infrastructure/traefik/cloudflare-secret.yaml

# Restart pods to pick up new secret
kubectl rollout restart deployment -n traefik
```

### Is TLS properly configured?

Yes, this setup:
- ✅ Uses Let's Encrypt certificates
- ✅ Enforces TLS 1.2+
- ✅ Uses strong cipher suites
- ✅ Auto-renews certificates
- ✅ Redirects HTTP to HTTPS

### How do I enable HTTPS-only?

Already enabled! Traefik redirects HTTP to HTTPS by default.

## Advanced Questions

### Can I run this in production?

Yes, but consider:
1. **Use Sealed Secrets** for secret management
2. **Enable ArgoCD HA** mode
3. **Set up monitoring** (Prometheus + Grafana)
4. **Configure backups**
5. **Use staging certificates** for testing first
6. **Implement network policies**
7. **Set up proper RBAC**

### How do I scale components?

```yaml
# Edit deployment
kubectl edit deployment <name> -n <namespace>

# Or scale directly
kubectl scale deployment <name> -n <namespace> --replicas=3

# Or update in Git (GitOps way)
# Edit YAML in Git, commit, push
```

### Can I use this with multiple clusters?

Yes! For multi-cluster:
1. Use ArgoCD ApplicationSets
2. Configure cluster secrets
3. Use cluster-specific overlays
4. Consider service mesh for cross-cluster

### How do I backup everything?

```bash
# Backup ArgoCD applications
argocd app list -o yaml > backup/argocd-apps.yaml

# Backup secrets (encrypt before storing!)
kubectl get secrets -A -o yaml > backup/secrets.yaml

# Backup certificates
kubectl get certificates -A -o yaml > backup/certificates.yaml

# Git is your primary backup!
```

### How do I migrate to a new cluster?

1. Install ArgoCD on new cluster
2. Run `./configure.sh` with your credentials
3. Apply root application: `kubectl apply -f root-app.yaml`
4. Wait for sync (15-20 minutes)
5. Update DNS to point to new cluster
6. Verify all services work

See disaster recovery in [ARCHITECTURE.md](ARCHITECTURE.md).

## Integration Questions

### Can I integrate with CI/CD?

Yes! Common patterns:
1. **Build**: CI builds and pushes images
2. **Update**: CI updates image tags in Git
3. **Deploy**: ArgoCD syncs changes automatically

Example with GitHub Actions:
```yaml
- name: Update image tag
  run: |
    sed -i "s|image:.*|image: myapp:${VERSION}|" apps/myapp/deployment.yaml
    git commit -am "Update myapp to ${VERSION}"
    git push
```

### Does this work with Helm charts?

Yes! See `infrastructure/traefik/helm-release.yaml` for example. ArgoCD supports:
- Raw Kubernetes YAML
- Helm charts
- Kustomize
- Jsonnet

### Can I use Kustomize?

Yes! Add kustomization.yaml files and ArgoCD will use them automatically.

Example:
```yaml
# apps/myapp/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - ingressroute.yaml
```

### How do I add monitoring?

Add Prometheus and Grafana:

```yaml
# infrastructure/monitoring/
# Add Prometheus operator
# Add Grafana
# Configure ServiceMonitors
```

See examples in community ArgoCD repos.

## Cost & Performance

### How much bandwidth does this use?

Minimal:
- ArgoCD polls Git: ~1-5 MB/day
- DDNS checks: ~1 MB/day
- cert-manager: Only during cert issuance
- Applications: Depends on your traffic

### What are the resource requirements?

Minimum:
- **CPU**: 2-4 cores
- **Memory**: 4-8 GB
- **Storage**: 20 GB

Recommended:
- **CPU**: 4-8 cores
- **Memory**: 8-16 GB
- **Storage**: 50 GB

### Can I reduce costs?

Yes:
1. Use smaller node sizes
2. Use spot/preemptible instances
3. Reduce replica counts
4. Use node auto-scaling
5. Optimize resource requests/limits

## Support

### Where can I get help?

1. **Documentation**: Check README, SETUP, and ARCHITECTURE docs
2. **Issues**: Search existing GitHub issues
3. **Discussions**: Start a GitHub discussion
4. **Community**: ArgoCD Slack, Kubernetes forums

### How do I report a bug?

1. Check if it's already reported
2. Provide steps to reproduce
3. Include logs and errors
4. Describe expected behavior
5. List your environment details

### Can I request features?

Yes! Open a GitHub issue with:
- Feature description
- Use case
- Why it's useful
- Proposed implementation (optional)

### How do I contribute?

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

Quick start:
1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## Miscellaneous

### What's Pangolin?

In this context, Pangolin refers to an authentication gateway (ForwardAuth). We're using traefik-forward-auth as the implementation for authentication middleware.

### Why ArgoCD?

ArgoCD provides:
- GitOps workflow
- Declarative configuration
- Automatic sync
- Rollback capabilities
- Multi-cluster support
- Great UI

### What's next after setup?

1. Add your own applications
2. Set up monitoring
3. Configure backups
4. Implement proper secret management
5. Add CI/CD integration
6. Scale as needed

### Can I use this for learning?

Absolutely! This is a great way to learn:
- Kubernetes
- GitOps
- ArgoCD
- Traefik
- cert-manager
- DevOps practices

---

**Still have questions?** Open a GitHub issue or discussion!
