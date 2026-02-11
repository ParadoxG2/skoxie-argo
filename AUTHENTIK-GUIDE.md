# Authentik Implementation Guide

This guide will help you implement **Authentik** as your authentication and identity provider (IdP) for the Skoxie ArgoCD infrastructure.

## 📖 What is Authentik?

[Authentik](https://goauthentik.io/) is an open-source Identity Provider focused on flexibility and versatility. It provides:

- 🔐 **Single Sign-On (SSO)** - OAuth2, SAML, LDAP
- 👥 **User Management** - Built-in user directory
- 🔑 **Multi-Factor Authentication (MFA)** - TOTP, WebAuthn, Duo
- 🎨 **Customizable** - Flows, policies, and branding
- 🔌 **Integrations** - Works with hundreds of applications
- 🛡️ **Security** - Forward authentication for Traefik

## 🏗️ Architecture Overview

```
User Request → Traefik → Authentik Forward Auth → Your Application
                  ↓
            Authentik IdP
         (Authentication & SSO)
```

Authentik will:
1. Intercept requests via Traefik ForwardAuth middleware
2. Authenticate users (login page if not authenticated)
3. Manage sessions and SSO
4. Forward authenticated requests to your apps

## 📋 Prerequisites

- Kubernetes cluster with this repository deployed
- Traefik ingress controller running
- cert-manager for SSL certificates
- PostgreSQL database (Authentik requires it)
- 2-4 GB additional RAM for Authentik

## 🚀 Quick Start

### Step 1: Add PostgreSQL (Authentik's Database)

Create `infrastructure/authentik/postgresql.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgresql-pvc
  namespace: authentik
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: authentik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
        - name: postgresql
          image: postgres:15-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: authentik
            - name: POSTGRES_USER
              value: authentik
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: authentik-secret
                  key: POSTGRES_PASSWORD
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: postgresql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: authentik
spec:
  selector:
    app: postgresql
  ports:
    - port: 5432
      targetPort: 5432
```

### Step 2: Add Redis (Authentik's Cache)

Create `infrastructure/authentik/redis.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: authentik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:7-alpine
          ports:
            - containerPort: 6379
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: authentik
spec:
  selector:
    app: redis
  ports:
    - port: 6379
      targetPort: 6379
```

### Step 3: Create Authentik Secrets

Create `infrastructure/authentik/secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: authentik-secret
  namespace: authentik
type: Opaque
stringData:
  # PostgreSQL password
  POSTGRES_PASSWORD: "CHANGE_THIS_POSTGRES_PASSWORD"
  
  # Authentik secret key - Generate with: openssl rand -base64 50
  AUTHENTIK_SECRET_KEY: "CHANGE_THIS_TO_SECURE_RANDOM_KEY_50_CHARS_MIN"
  
  # Initial admin password (you can change it after first login)
  AUTHENTIK_BOOTSTRAP_PASSWORD: "CHANGE_THIS_INITIAL_ADMIN_PASSWORD"
  
  # Email configuration (optional, for password resets)
  AUTHENTIK_EMAIL__HOST: "smtp.gmail.com"
  AUTHENTIK_EMAIL__PORT: "587"
  AUTHENTIK_EMAIL__USERNAME: "your-email@gmail.com"
  AUTHENTIK_EMAIL__PASSWORD: "your-app-password"
  AUTHENTIK_EMAIL__FROM: "authentik@woxie.xyz"
```

### Step 4: Create Authentik Server Deployment

Create `infrastructure/authentik/server.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authentik-server
  namespace: authentik
  labels:
    app: authentik
    component: server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: authentik
      component: server
  template:
    metadata:
      labels:
        app: authentik
        component: server
    spec:
      containers:
        - name: authentik
          image: ghcr.io/goauthentik/server:2024.2.0
          args: ["server"]
          ports:
            - name: http
              containerPort: 9000
            - name: https
              containerPort: 9443
          env:
            - name: AUTHENTIK_REDIS__HOST
              value: "redis"
            - name: AUTHENTIK_POSTGRESQL__HOST
              value: "postgresql"
            - name: AUTHENTIK_POSTGRESQL__NAME
              value: "authentik"
            - name: AUTHENTIK_POSTGRESQL__USER
              value: "authentik"
            - name: AUTHENTIK_POSTGRESQL__PASSWORD
              valueFrom:
                secretKeyRef:
                  name: authentik-secret
                  key: POSTGRES_PASSWORD
            - name: AUTHENTIK_SECRET_KEY
              valueFrom:
                secretKeyRef:
                  name: authentik-secret
                  key: AUTHENTIK_SECRET_KEY
            - name: AUTHENTIK_BOOTSTRAP_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: authentik-secret
                  key: AUTHENTIK_BOOTSTRAP_PASSWORD
            - name: AUTHENTIK_BOOTSTRAP_EMAIL
              value: "admin@woxie.xyz"
            # External URL (important for proper redirects)
            - name: AUTHENTIK_HOST
              value: "https://auth.woxie.xyz"
            - name: AUTHENTIK_INSECURE
              value: "false"
            - name: AUTHENTIK_LOG_LEVEL
              value: "info"
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "1000m"
          livenessProbe:
            httpGet:
              path: /-/health/live/
              port: 9000
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /-/health/ready/
              port: 9000
            initialDelaySeconds: 30
            periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: authentik-server
  namespace: authentik
spec:
  selector:
    app: authentik
    component: server
  ports:
    - name: http
      port: 9000
      targetPort: 9000
    - name: https
      port: 9443
      targetPort: 9443
```

### Step 5: Create Authentik Worker Deployment

Create `infrastructure/authentik/worker.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authentik-worker
  namespace: authentik
  labels:
    app: authentik
    component: worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: authentik
      component: worker
  template:
    metadata:
      labels:
        app: authentik
        component: worker
    spec:
      containers:
        - name: authentik
          image: ghcr.io/goauthentik/server:2024.2.0
          args: ["worker"]
          env:
            - name: AUTHENTIK_REDIS__HOST
              value: "redis"
            - name: AUTHENTIK_POSTGRESQL__HOST
              value: "postgresql"
            - name: AUTHENTIK_POSTGRESQL__NAME
              value: "authentik"
            - name: AUTHENTIK_POSTGRESQL__USER
              value: "authentik"
            - name: AUTHENTIK_POSTGRESQL__PASSWORD
              valueFrom:
                secretKeyRef:
                  name: authentik-secret
                  key: POSTGRES_PASSWORD
            - name: AUTHENTIK_SECRET_KEY
              valueFrom:
                secretKeyRef:
                  name: authentik-secret
                  key: AUTHENTIK_SECRET_KEY
            - name: AUTHENTIK_HOST
              value: "https://auth.woxie.xyz"
            - name: AUTHENTIK_INSECURE
              value: "false"
            - name: AUTHENTIK_LOG_LEVEL
              value: "info"
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

### Step 6: Create Namespace

Create `infrastructure/authentik/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: authentik
  labels:
    name: authentik
```

### Step 7: Create Traefik IngressRoute

Create `infrastructure/authentik/ingressroute.yaml`:

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
  tls:
    certResolver: cloudflare
```

### Step 8: Create ForwardAuth Middleware

Create `infrastructure/authentik/middleware.yaml`:

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
    authResponseHeaders:
      - X-authentik-username
      - X-authentik-groups
      - X-authentik-email
      - X-authentik-name
      - X-authentik-uid
```

### Step 9: Create ArgoCD Application

Create `bootstrap/authentik-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: authentik
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/ParadoxG2/skoxie-argo.git
    targetRevision: HEAD
    path: infrastructure/authentik
  destination:
    server: https://kubernetes.default.svc
    namespace: authentik
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Step 10: Update Root Application

Edit `root-app.yaml` to include the authentik application:

```yaml
# Add to the bootstrap directory sources:
- path: bootstrap/authentik-app.yaml
```

Or manually apply:
```bash
kubectl apply -f bootstrap/authentik-app.yaml
```

## ⚙️ Configuration

### Initial Setup

1. **Deploy everything:**
```bash
kubectl apply -f infrastructure/authentik/
kubectl apply -f bootstrap/authentik-app.yaml
```

2. **Wait for deployment:**
```bash
kubectl get pods -n authentik -w
```

3. **Access Authentik:**
   - URL: https://auth.woxie.xyz
   - Username: `admin@woxie.xyz`
   - Password: (from `AUTHENTIK_BOOTSTRAP_PASSWORD` in secret)

### Configure Authentik for Forward Auth

1. **Log in to Authentik admin interface**

2. **Create an Application:**
   - Navigate to **Applications** → **Create**
   - Name: `Traefik Forward Auth`
   - Slug: `traefik-forward-auth`

3. **Create a Provider:**
   - Navigate to **Applications** → **Providers** → **Create**
   - Type: **Proxy Provider**
   - Name: `Traefik Proxy Provider`
   - Authorization flow: `default-provider-authorization-implicit-consent`
   - External host: `https://auth.woxie.xyz`
   - Mode: **Forward auth (single application)**
   - Save the provider

4. **Link Provider to Application:**
   - Edit your application
   - Select the provider you just created
   - Save

5. **Create an Outpost:**
   - Navigate to **Outposts** → **Create**
   - Name: `Traefik Outpost`
   - Type: **Proxy**
   - Select your application
   - Integration: Use the embedded outpost (runs in the authentik-server pods)

## 🔐 Protecting Your Applications

### Method 1: Using Authentik Middleware

Add the authentik middleware to your application's IngressRoute:

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

### Method 2: Per-Application Configuration in Authentik

1. In Authentik, create a new **Application** for each service
2. Create a **Provider** (Proxy Provider in Forward Auth mode)
3. Configure the external host for each application
4. Update the middleware to point to the specific outpost

Example for multiple apps:

```yaml
# In Authentik UI:
# Application 1: Whoami (https://whoami.woxie.xyz)
# Application 2: Grafana (https://grafana.woxie.xyz)
# Application 3: ArgoCD (https://argocd.woxie.xyz)
```

## 🎨 Customization

### Custom Login Page

1. Navigate to **Customisation** → **Flows**
2. Edit the `default-authentication-flow`
3. Customize stages, add MFA, change branding

### Add OAuth/OIDC Providers

1. Navigate to **Directory** → **Federation & Social login**
2. Add providers (Google, GitHub, GitLab, etc.)
3. Configure OAuth credentials
4. Enable for login flow

### Configure MFA

1. Navigate to **Flows** → **Stages**
2. Create TOTP or WebAuthn stages
3. Add to authentication flow
4. Configure policies for when MFA is required

## 🔧 Troubleshooting

### Check Authentik Logs

```bash
# Server logs
kubectl logs -n authentik -l component=server -f

# Worker logs
kubectl logs -n authentik -l component=worker -f

# PostgreSQL logs
kubectl logs -n authentik -l app=postgresql -f
```

### Common Issues

#### 1. "Connection refused" errors
- Check if PostgreSQL is running: `kubectl get pods -n authentik`
- Verify database password in secrets

#### 2. Authentik not accessible
- Check IngressRoute: `kubectl get ingressroute -n authentik`
- Verify certificate: `kubectl get certificate -A`
- Check DNS resolution

#### 3. Forward auth not working
- Verify middleware configuration
- Check Authentik outpost status in UI
- Review Traefik logs: `kubectl logs -n traefik -l app.kubernetes.io/name=traefik`

#### 4. Redirect loops
- Ensure `AUTHENTIK_HOST` matches your external URL
- Check that `trustForwardHeader: true` in middleware
- Verify cookie domain settings

### Debug ForwardAuth

Test the forward auth endpoint:

```bash
kubectl port-forward -n authentik svc/authentik-server 9000:9000

# Test auth endpoint
curl -v http://localhost:9000/outpost.goauthentik.io/auth/traefik
```

## 📊 Monitoring

### Health Checks

```bash
# Check Authentik health
kubectl exec -n authentik deployment/authentik-server -- wget -O- http://localhost:9000/-/health/live/

# Check all components
kubectl get all -n authentik
```

### Resource Usage

```bash
# Check resource usage
kubectl top pods -n authentik
```

## 🔄 Migration from Pangolin

If you're migrating from the existing Pangolin setup:

1. **Keep Pangolin running** during migration
2. **Deploy Authentik** alongside
3. **Test with one application** first
4. **Gradually migrate** applications
5. **Remove Pangolin** when all apps are migrated

### Migration Steps

```bash
# 1. Deploy Authentik
kubectl apply -f infrastructure/authentik/

# 2. Test with one app
# Update one IngressRoute to use authentik middleware

# 3. Verify it works
# Access the app, ensure auth works

# 4. Migrate remaining apps
# Update all IngressRoutes

# 5. Remove Pangolin (optional)
kubectl delete namespace pangolin
```

## 🚀 Advanced Configuration

### High Availability

For production, increase replicas:

```yaml
# server.yaml
spec:
  replicas: 3  # Increase from 2

# worker.yaml
spec:
  replicas: 2  # Increase from 1

# postgresql.yaml - Consider external managed database
# redis.yaml - Consider Redis cluster
```

### External Database

For production, use managed PostgreSQL:

```yaml
env:
  - name: AUTHENTIK_POSTGRESQL__HOST
    value: "your-postgres.rds.amazonaws.com"
  - name: AUTHENTIK_POSTGRESQL__NAME
    value: "authentik"
  - name: AUTHENTIK_POSTGRESQL__USER
    value: "authentik"
  - name: AUTHENTIK_POSTGRESQL__PASSWORD
    valueFrom:
      secretKeyRef:
        name: authentik-secret
        key: POSTGRES_PASSWORD
```

### Backup Strategy

```bash
# Backup PostgreSQL
kubectl exec -n authentik deployment/postgresql -- pg_dump -U authentik authentik > backup.sql

# Backup Authentik configuration
kubectl get -n authentik -o yaml secrets,configmaps > authentik-config-backup.yaml
```

## 📚 Resources

- [Authentik Documentation](https://goauthentik.io/docs/)
- [Authentik GitHub](https://github.com/goauthentik/authentik)
- [Traefik ForwardAuth](https://doc.traefik.io/traefik/middlewares/http/forwardauth/)
- [Authentik with Traefik](https://goauthentik.io/docs/providers/proxy/traefik)

## 🎯 Next Steps

1. ✅ Deploy Authentik infrastructure
2. ✅ Access admin interface
3. ✅ Configure forward auth provider
4. ✅ Test with one application
5. ✅ Migrate all applications
6. ✅ Configure MFA
7. ✅ Add external OAuth providers
8. ✅ Set up monitoring
9. ✅ Configure backups

---

**Questions?** Check the [FAQ](FAQ.md) or open a GitHub issue!
