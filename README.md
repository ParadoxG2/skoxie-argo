# Skoxie ArgoCD - General Purpose GitOps Repository

A production-ready ArgoCD repository for managing Kubernetes applications with Traefik ingress, cert-manager for SSL certificates, Cloudflare DDNS integration, and Pangolin authentication.

## 🚀 Features

### Core Infrastructure
- **ArgoCD** - GitOps continuous delivery
- **Traefik** - Modern HTTP reverse proxy and load balancer
- **cert-manager** - Automated SSL/TLS certificate management with Let's Encrypt
- **Cloudflare DDNS** - Automatic DNS updates for woxie.xyz domain
- **Authentik Authentication** - Modern identity provider with SSO and forward authentication
- **Easy Configuration** - Simple YAML-based configuration
- **Auto-Sync** - Automated deployment of changes

### Media Stack (Full arr-stack)
- **Prowlarr** - Indexer manager for automation apps
- **Sonarr** - TV show automation and management
- **Radarr** - Movie automation and management
- **Lidarr** - Music automation and management
- **Readarr** - Book/audiobook automation and management
- **Bazarr** - Subtitle management
- **Jellyfin** - Media streaming server
- **slskd** - Soulseek daemon for P2P sharing
- **Tdarr** - Automated media transcoding
- **Nextcloud** - Personal cloud storage

All media services are secured with Authentik authentication via Traefik.

## 📋 Prerequisites

1. A Kubernetes cluster (v1.24+)
2. kubectl configured to access your cluster
3. ArgoCD installed in your cluster
4. A Cloudflare account with:
   - Domain: woxie.xyz
   - API Token with DNS edit permissions
5. (Optional) OAuth provider for Pangolin authentication

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

#### infrastructure/authentik/secret.yaml
```yaml
stringData:
  POSTGRES_PASSWORD: "GENERATE_A_SECURE_RANDOM_STRING"
  AUTHENTIK_SECRET_KEY: "GENERATE_A_SECURE_RANDOM_STRING"
  AUTHENTIK_BOOTSTRAP_PASSWORD: "GENERATE_A_SECURE_PASSWORD"
  AUTHENTIK_BOOTSTRAP_TOKEN: "GENERATE_A_SECURE_TOKEN"
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
- authentik
- pangolin (middleware only)
- example-apps

### 5. Access Services

Once DNS has propagated, you can access:

#### Infrastructure Services
- **Traefik Dashboard**: https://traefik.woxie.xyz
- **ArgoCD UI**: https://argocd.woxie.xyz (configure IngressRoute for ArgoCD)
- **Authentik (Identity Provider)**: https://auth.woxie.xyz
- **Example Whoami App**: https://whoami.woxie.xyz
- **Example Hello World**: https://hello.woxie.xyz

#### Media Stack Services (secured with Authentik)
- **Prowlarr**: https://prowlarr.woxie.xyz
- **Sonarr**: https://sonarr.woxie.xyz
- **Radarr**: https://radarr.woxie.xyz
- **Lidarr**: https://lidarr.woxie.xyz
- **Readarr**: https://readarr.woxie.xyz
- **Bazarr**: https://bazarr.woxie.xyz
- **Jellyfin**: https://jellyfin.woxie.xyz
- **slskd**: https://slskd.woxie.xyz
- **Tdarr**: https://tdarr.woxie.xyz
- **Nextcloud**: https://nextcloud.woxie.xyz

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
│   ├── authentik-app.yaml    # Authentik identity provider
│   ├── pangolin-app.yaml     # Legacy middleware reference
│   ├── media-apps.yaml       # Media stack application
│   └── apps.yaml             # Example apps
├── infrastructure/
│   ├── traefik/              # Traefik ingress controller
│   ├── cert-manager/         # SSL certificate management
│   ├── cloudflare-ddns/      # DDNS updater
│   ├── authentik/            # Authentik identity provider
│   ├── pangolin/             # Authentication middleware (uses Authentik)
│   └── media-apps/           # Complete media automation stack
│       ├── prowlarr.yaml     # Indexer manager
│       ├── sonarr.yaml       # TV shows
│       ├── radarr.yaml       # Movies
│       ├── lidarr.yaml       # Music
│       ├── readarr.yaml      # Books
│       ├── bazarr.yaml       # Subtitles
│       ├── jellyfin.yaml     # Media server
│       ├── slskd.yaml        # Soulseek daemon
│       ├── tdarr.yaml        # Transcoding
│       └── nextcloud.yaml    # Cloud storage
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

### Authentik Authentication

Authentik is a modern identity provider (IdP) that provides SSO, OAuth2, SAML, and forward authentication. To enable authentication on your apps, add the middleware to your IngressRoute:

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

#### Initial Authentik Setup

After deployment, access Authentik at https://auth.woxie.xyz and complete the initial setup:

1. Use the bootstrap credentials from `infrastructure/authentik/secret.yaml`
2. Create your first admin user
3. Configure applications and providers
4. Set up authentication flows
5. Configure forward authentication for Traefik

For detailed Authentik configuration, visit: https://goauthentik.io/docs/

**📖 See [AUTHENTIK-SETUP.md](AUTHENTIK-SETUP.md) for a complete setup guide.**

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

- [Authentik Setup Guide](AUTHENTIK-SETUP.md) - Complete guide for configuring Authentik
- [Authentik Quick Reference](AUTHENTIK-QUICKREF.md) - Common commands and tasks
- [Media Stack Guide](infrastructure/media-apps/README.md) - Complete guide for the media automation stack
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)

## 🎬 Media Stack Setup

The repository includes a complete media automation stack with all services secured by Authentik authentication:

**Services Included:**
- Prowlarr (indexer manager) + Full arr-stack (Sonarr, Radarr, Lidarr, Readarr, Bazarr)
- Jellyfin (media streaming)
- slskd (Soulseek daemon)
- Tdarr (transcoding)
- Nextcloud (cloud storage)

**Quick Start:**

1. Update Nextcloud secrets in `infrastructure/media-apps/nextcloud.yaml`
2. The media stack will be automatically deployed via ArgoCD
3. Configure Authentik authentication (see [AUTHENTIK-SETUP.md](AUTHENTIK-SETUP.md))
4. Access services at `<service>.woxie.xyz`
5. Follow the [Media Stack Guide](infrastructure/media-apps/README.md) for detailed setup instructions

All media services share storage volumes for efficient space usage and seamless integration.

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
3. Update Nextcloud database passwords in `infrastructure/media-apps/nextcloud.yaml`
4. Deploy the root application
5. Configure Authentik for authentication
6. Set up your media stack (see [Media Stack Guide](infrastructure/media-apps/README.md))
7. Add your own applications
8. Enjoy automated GitOps deployments!

---

Built with ❤️ for woxie.xyz
