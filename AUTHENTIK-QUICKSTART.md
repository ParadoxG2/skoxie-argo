# Quick Start: Implementing Authentik

This is a quick reference guide to get you started with Authentik authentication in under 30 minutes.

## 🎯 What You'll Get

- **Single Sign-On (SSO)** - Users log in once, access all apps
- **User Management** - Built-in user directory
- **Multi-Factor Authentication** - TOTP, WebAuthn, SMS
- **OAuth2/OIDC** - Modern authentication standards
- **SAML** - Enterprise SSO support
- **Forward Auth** - Protect any app with Traefik

## ⚡ Quick Setup (5 Steps)

### Step 1: Update Secrets

Edit `infrastructure/authentik/secret.yaml`:

```bash
cd /home/runner/work/skoxie-argo/skoxie-argo

# Generate a secure secret key (minimum 50 characters)
openssl rand -base64 50

# Edit the secret file
vim infrastructure/authentik/secret.yaml
```

Update these values:
- `POSTGRES_PASSWORD` - Set a strong password
- `AUTHENTIK_SECRET_KEY` - Use the generated key above
- `AUTHENTIK_BOOTSTRAP_PASSWORD` - Set initial admin password

### Step 2: Deploy Authentik

```bash
# Deploy via ArgoCD
kubectl apply -f bootstrap/authentik-app.yaml

# OR deploy directly
kubectl apply -f infrastructure/authentik/
```

### Step 3: Wait for Deployment

```bash
# Watch deployment progress (takes 2-5 minutes)
kubectl get pods -n authentik -w

# All pods should be Running:
# - postgresql-xxx
# - redis-xxx
# - authentik-server-xxx (2 replicas)
# - authentik-worker-xxx
```

### Step 4: Access Authentik

```bash
# Once DNS propagates (5-10 minutes), access:
# URL: https://auth.woxie.xyz
# Username: admin@woxie.xyz
# Password: (your AUTHENTIK_BOOTSTRAP_PASSWORD)

# Or use port-forward immediately:
kubectl port-forward -n authentik svc/authentik-server 9000:9000
# Then access: http://localhost:9000
```

### Step 5: Configure ForwardAuth

In Authentik UI:

1. **Create Provider:**
   - Go to **Applications** → **Providers** → **Create**
   - Type: **Proxy Provider**
   - Name: `Traefik Forward Auth`
   - Authorization flow: `default-provider-authorization-implicit-consent`
   - Mode: **Forward auth (single application)**
   - External host: `https://auth.woxie.xyz`
   - Save

2. **Create Application:**
   - Go to **Applications** → **Create**
   - Name: `Traefik Forward Auth`
   - Slug: `traefik-forward-auth`
   - Provider: Select the provider you just created
   - Save

3. **Create Outpost:**
   - Go to **Outposts** → **Create**
   - Name: `Traefik Outpost`
   - Type: **Proxy**
   - Applications: Select your application
   - Save

Done! 🎉

## 🔐 Protect Your First App

Add authentication to an existing app:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: whoami
  namespace: demo-apps
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`whoami.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: whoami
          port: 80
  tls:
    certResolver: cloudflare
```

Apply and test:
```bash
kubectl apply -f whoami-protected.yaml

# Access the app - you'll be redirected to login
curl -L https://whoami.woxie.xyz
```

## 📋 YAML Structure Required

Here's the minimal YAML structure you need:

### 1. Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: authentik
```

### 2. Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: authentik-secret
  namespace: authentik
stringData:
  POSTGRES_PASSWORD: "your-password"
  AUTHENTIK_SECRET_KEY: "your-50-char-key"
  AUTHENTIK_BOOTSTRAP_PASSWORD: "admin-password"
```

### 3. PostgreSQL
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: authentik
spec:
  # ... (see infrastructure/authentik/postgresql.yaml)
```

### 4. Redis
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: authentik
spec:
  # ... (see infrastructure/authentik/redis.yaml)
```

### 5. Authentik Server
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authentik-server
  namespace: authentik
spec:
  # ... (see infrastructure/authentik/server.yaml)
```

### 6. Authentik Worker
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authentik-worker
  namespace: authentik
spec:
  # ... (see infrastructure/authentik/worker.yaml)
```

### 7. IngressRoute
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: authentik
  namespace: authentik
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`auth.woxie.xyz`)
      kind: Rule
      services:
        - name: authentik-server
          port: 9000
```

### 8. Middleware
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: authentik
  namespace: authentik
spec:
  forwardAuth:
    address: http://authentik-server.authentik.svc.cluster.local:9000/outpost.goauthentik.io/auth/traefik
    trustForwardHeader: true
```

## 🎨 Customization

### Add External OAuth Provider (e.g., Google)

1. In Authentik UI, go to **Directory** → **Federation & Social login**
2. Click **Create**
3. Select **Google**
4. Enter your Google OAuth credentials
5. Save

Now users can log in with Google!

### Enable MFA

1. Go to **Flows & Stages**
2. Edit `default-authentication-flow`
3. Add **Authenticator Validation Stage**
4. Configure TOTP or WebAuthn
5. Save

Users will be prompted to set up MFA on next login.

### Custom Branding

1. Go to **Customisation** → **Tenants**
2. Edit **Default Tenant**
3. Upload logo, change colors, etc.
4. Save

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n authentik authentik-server-xxx

# Common issues:
# - PostgreSQL password mismatch
# - Secret key too short (must be 50+ chars)
# - Insufficient resources
```

### Can't Access UI

```bash
# Check IngressRoute
kubectl get ingressroute -n authentik

# Check certificate
kubectl get certificate -A | grep auth

# Use port-forward as workaround
kubectl port-forward -n authentik svc/authentik-server 9000:9000
```

### Authentication Not Working

```bash
# Verify middleware exists
kubectl get middleware -n authentik

# Check Authentik logs
kubectl logs -n authentik -l component=server -f

# Test auth endpoint
kubectl exec -n traefik deployment/traefik -- \
  wget -O- http://authentik-server.authentik.svc.cluster.local:9000/-/health/live/
```

## 📚 Next Steps

1. ✅ Deploy Authentik
2. ✅ Configure ForwardAuth
3. ✅ Protect your first app
4. ⬜ Add external OAuth providers
5. ⬜ Enable MFA
6. ⬜ Create user groups
7. ⬜ Set up group-based policies
8. ⬜ Protect all your apps

## 📖 Full Documentation

For complete details, see:

- [AUTHENTIK-GUIDE.md](AUTHENTIK-GUIDE.md) - Complete implementation guide
- [YAML-STRUCTURE-GUIDE.md](YAML-STRUCTURE-GUIDE.md) - YAML reference
- [infrastructure/authentik/EXAMPLE.md](infrastructure/authentik/EXAMPLE.md) - More examples
- [infrastructure/authentik/README.md](infrastructure/authentik/README.md) - Component details

## 🆘 Need Help?

- Check [FAQ.md](FAQ.md)
- Open a [GitHub Issue](https://github.com/ParadoxG2/skoxie-argo/issues)
- Read [Authentik Documentation](https://goauthentik.io/docs/)

---

**That's it!** You now have enterprise-grade authentication for your Kubernetes apps. 🚀
