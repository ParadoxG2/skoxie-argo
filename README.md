# Skoxie ArgoCD - General Purpose GitOps Repository

A production-ready ArgoCD repository for managing Kubernetes applications with Traefik ingress, cert-manager for SSL certificates, Cloudflare DDNS integration, and authentication options (Pangolin/Authentik).

## 🚀 Features

- **ArgoCD** - GitOps continuous delivery
- **Traefik** - Modern HTTP reverse proxy and load balancer
- **cert-manager** - Automated SSL/TLS certificate management with Let's Encrypt
- **Cloudflare DDNS** - Automatic DNS updates for woxie.xyz domain
- **Pangolin Authentication** - Forward authentication middleware for securing apps
- **Authentik Support** - Modern identity provider with SSO, MFA, and OAuth2/SAML (see [AUTHENTIK-GUIDE.md](AUTHENTIK-GUIDE.md))
- **Easy Configuration** - Simple YAML-based configuration
- **Auto-Sync** - Automated deployment of changes

## 📋 Prerequisites

1. A Kubernetes cluster (v1.24+)
2. kubectl configured to access your cluster
3. ArgoCD installed in your cluster
4. A Cloudflare account with:
   - Domain: woxie.xyz
   - API Token with DNS edit permissions
5. (Optional) OAuth provider for Pangolin authentication or deploy Authentik

## 🔧 Quick Start

### 1. Install ArgoCD (if not already installed)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for ArgoCD to be ready:
```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2. Configure Your Secrets

Before deploying, update the following files with your actual credentials:

#### config/values.yaml
```yaml
cloudflare:
  apiToken: "YOUR_CLOUDFLARE_API_TOKEN"
  email: "YOUR_EMAIL@example.com"

certManager:
  email: "YOUR_EMAIL@example.com"
```

#### infrastructure/traefik/cloudflare-secret.yaml
```yaml
stringData:
  email: "YOUR_EMAIL@example.com"
  apiToken: "YOUR_CLOUDFLARE_API_TOKEN"
```

#### infrastructure/cert-manager/cloudflare-secret.yaml
```yaml
stringData:
  api-token: "YOUR_CLOUDFLARE_API_TOKEN"
```

#### infrastructure/cert-manager/cluster-issuer-production.yaml
```yaml
email: YOUR_EMAIL@example.com
```

#### infrastructure/cloudflare-ddns/secret.yaml
```yaml
stringData:
  CLOUDFLARE_API_TOKEN: "YOUR_CLOUDFLARE_API_TOKEN"
```

#### infrastructure/pangolin/secret.yaml
```yaml
stringData:
  SESSION_SECRET: "GENERATE_A_SECURE_RANDOM_STRING"
  OAUTH_CLIENT_ID: "YOUR_OAUTH_CLIENT_ID"
  OAUTH_CLIENT_SECRET: "YOUR_OAUTH_CLIENT_SECRET"
```

### 3. Deploy the Root Application

```bash
kubectl apply -f root-app.yaml
```

This will deploy all infrastructure components automatically via ArgoCD.

### 4. Verify Deployment

Check ArgoCD applications:
```bash
kubectl get applications -n argocd
```

Expected applications:
- root-app
- traefik
- cert-manager
- cloudflare-ddns
- pangolin
- example-apps

### 5. Access Services

Once DNS has propagated, you can access:

- **Traefik Dashboard**: https://traefik.woxie.xyz
- **ArgoCD UI**: https://argocd.woxie.xyz (configure IngressRoute for ArgoCD)
- **Pangolin Auth**: https://auth.woxie.xyz
- **Example Whoami App**: https://whoami.woxie.xyz
- **Example Hello World**: https://hello.woxie.xyz

## 📁 Repository Structure

```
.
├── root-app.yaml              # Root ArgoCD application
├── config/
│   └── values.yaml           # Global configuration values
├── bootstrap/
│   ├── traefik-app.yaml      # Traefik ArgoCD application
│   ├── cert-manager-app.yaml # cert-manager ArgoCD application
│   ├── cloudflare-ddns-app.yaml
│   ├── pangolin-app.yaml
│   └── apps.yaml             # Example apps
├── infrastructure/
│   ├── traefik/              # Traefik ingress controller
│   ├── cert-manager/         # SSL certificate management
│   ├── cloudflare-ddns/      # DDNS updater
│   └── pangolin/             # Authentication gateway
└── apps/
    ├── whoami-app.yaml       # Example: Whoami application
    └── hello-world-app.yaml  # Example: Hello World app
```

## 🔐 Security Configuration

### Cloudflare API Token

Create a Cloudflare API Token with these permissions:
- Zone - DNS - Edit
- Zone - Zone - Read

### Let's Encrypt

The setup uses Let's Encrypt for SSL certificates:
- **Production**: `letsencrypt-production` (rate limited)
- **Staging**: `letsencrypt-staging` (for testing)

To use staging certificates (recommended for testing):
Edit `infrastructure/cert-manager/wildcard-certificate.yaml`:
```yaml
issuerRef:
  name: letsencrypt-staging  # Changed from letsencrypt-production
```

### Pangolin Authentication

To enable authentication on your apps, add the middleware to your IngressRoute:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myapp.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: pangolin-auth
          namespace: pangolin
      services:
        - name: my-app
          port: 80
  tls:
    certResolver: cloudflare
```

### Authentik Authentication (Alternative)

For a more feature-rich authentication solution with SSO, MFA, and user management:

1. **Deploy Authentik**:
   ```bash
   kubectl apply -f bootstrap/authentik-app.yaml
   ```

2. **Configure secrets** in `infrastructure/authentik/secret.yaml`

3. **Add authentication** to your apps:
   ```yaml
   middlewares:
     - name: authentik
       namespace: authentik
   ```

See [AUTHENTIK-GUIDE.md](AUTHENTIK-GUIDE.md) for complete implementation guide.

## 📝 Adding New Applications

1. Create application manifests in `apps/` directory
2. Create an ArgoCD Application manifest
3. Commit and push changes
4. ArgoCD will automatically sync and deploy

Example application structure:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-namespace
spec:
  # ... deployment spec ...
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: my-namespace
spec:
  # ... service spec ...
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-namespace
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`my-app.woxie.xyz`)
      kind: Rule
      services:
        - name: my-app
          port: 80
  tls:
    certResolver: cloudflare
```

## 🔄 Updating Applications

All changes are managed through Git:

1. Make changes to manifests
2. Commit and push to repository
3. ArgoCD automatically syncs changes

Manual sync (if needed):
```bash
argocd app sync <app-name>
```

## 🐛 Troubleshooting

### Check ArgoCD Application Status
```bash
kubectl get applications -n argocd
argocd app get <app-name>
```

### Check Traefik Logs
```bash
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f
```

### Check cert-manager Certificates
```bash
kubectl get certificates -A
kubectl describe certificate woxie-xyz-wildcard -n traefik
```

### Check Cloudflare DDNS Logs
```bash
kubectl logs -n cloudflare-ddns -l app=cloudflare-ddns -f
```

### DNS Not Resolving
- Wait 5-10 minutes for DDNS to update
- Check Cloudflare dashboard for DNS records
- Verify API token has correct permissions

### Certificate Issues
- Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager -f`
- Verify Cloudflare API token in secrets
- Try staging issuer first before production

## 📚 Documentation

### Core Components
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)

### Authentication & Guides
- [AUTHENTIK-GUIDE.md](AUTHENTIK-GUIDE.md) - Complete guide for implementing Authentik SSO
- [Authentik Documentation](https://goauthentik.io/docs/)
- [GETTING-STARTED.md](GETTING-STARTED.md) - Quick start guide
- [SETUP.md](SETUP.md) - Detailed setup instructions
- [FAQ.md](FAQ.md) - Frequently asked questions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🎯 Next Steps

1. Configure your Cloudflare API credentials
2. Update email addresses in configuration files
3. Deploy the root application
4. Add your own applications
5. Enjoy automated GitOps deployments!

---

Built with ❤️ for woxie.xyz
