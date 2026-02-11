# YAML Structure Reference

This guide provides quick reference templates for common YAML structures used in this repository.

## 📋 Table of Contents

1. [Namespace](#namespace)
2. [Deployment](#deployment)
3. [Service](#service)
4. [IngressRoute (Traefik)](#ingressroute)
5. [IngressRoute with Authentication](#ingressroute-with-authentication)
6. [Secret](#secret)
7. [ConfigMap](#configmap)
8. [PersistentVolumeClaim](#persistentvolumeclaim)
9. [ArgoCD Application](#argocd-application)
10. [Middleware](#middleware)

---

## Namespace

Create a namespace for your application:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    name: my-app
```

---

## Deployment

Deploy your application:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-app
  labels:
    app: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          ports:
            - containerPort: 8080
              name: http
          env:
            - name: ENV_VAR
              value: "value"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```

---

## Service

Expose your application:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: my-app
  labels:
    app: my-app
spec:
  selector:
    app: my-app
  ports:
    - name: http
      port: 80
      targetPort: 8080
      protocol: TCP
  type: ClusterIP
```

---

## IngressRoute

Make your app accessible via Traefik (without authentication):

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-app
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myapp.woxie.xyz`)
      kind: Rule
      services:
        - name: my-app
          port: 80
  tls:
    certResolver: cloudflare
```

---

## IngressRoute with Authentication

Protect your app with authentication:

### With Pangolin

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-app
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

### With Authentik

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-app
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myapp.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: my-app
          port: 80
  tls:
    certResolver: cloudflare
```

---

## Secret

Store sensitive information:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: my-app
type: Opaque
stringData:
  # Plain text - will be encoded to base64 automatically
  USERNAME: "admin"
  PASSWORD: "super-secret-password"
  API_KEY: "your-api-key-here"
```

Or with base64-encoded data:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: my-app
type: Opaque
data:
  # Base64 encoded values
  USERNAME: YWRtaW4=
  PASSWORD: c3VwZXItc2VjcmV0LXBhc3N3b3Jk
```

Generate base64:
```bash
echo -n "my-value" | base64
```

---

## ConfigMap

Store configuration data:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
  namespace: my-app
data:
  # Simple key-value pairs
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  
  # Configuration file
  app.conf: |
    [server]
    host = 0.0.0.0
    port = 8080
    
    [database]
    host = postgres
    port = 5432
```

---

## PersistentVolumeClaim

Request storage for your application:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
  namespace: my-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # Optional: storageClassName
  # storageClassName: fast-ssd
```

Use in Deployment:

```yaml
spec:
  template:
    spec:
      containers:
        - name: my-app
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: my-app-storage
```

---

## ArgoCD Application

Deploy your app with ArgoCD:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/ParadoxG2/skoxie-argo.git
    targetRevision: HEAD
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Middleware

### Basic Auth Middleware

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
  namespace: my-app
spec:
  basicAuth:
    secret: auth-secret
```

Create the secret:
```bash
# Generate password
htpasswd -nb admin password | base64

# Create secret
kubectl create secret generic auth-secret \
  --from-literal=users='admin:$apr1$...' \
  -n my-app
```

### Rate Limiting Middleware

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: my-app
spec:
  rateLimit:
    average: 100
    burst: 50
```

### Headers Middleware

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: security-headers
  namespace: my-app
spec:
  headers:
    customResponseHeaders:
      X-Frame-Options: "DENY"
      X-Content-Type-Options: "nosniff"
    sslRedirect: true
    stsSeconds: 31536000
    stsIncludeSubdomains: true
    stsPreload: true
```

### Chain Multiple Middlewares

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-app
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myapp.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: rate-limit
          namespace: my-app
        - name: security-headers
          namespace: my-app
        - name: authentik
          namespace: authentik
      services:
        - name: my-app
          port: 80
  tls:
    certResolver: cloudflare
```

---

## Complete Application Example

Here's a complete example with all components:

```yaml
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: demo-app
---
# Secret
apiVersion: v1
kind: Secret
metadata:
  name: demo-secret
  namespace: demo-app
type: Opaque
stringData:
  DB_PASSWORD: "super-secret"
---
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-config
  namespace: demo-app
data:
  APP_ENV: "production"
---
# PersistentVolumeClaim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-storage
  namespace: demo-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
        - name: app
          image: nginx:alpine
          ports:
            - containerPort: 80
          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: demo-config
                  key: APP_ENV
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: demo-secret
                  key: DB_PASSWORD
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "500m"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: demo-storage
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: demo-app
spec:
  selector:
    app: demo-app
  ports:
    - port: 80
      targetPort: 80
---
# IngressRoute
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: demo-app
  namespace: demo-app
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`demo.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: demo-app
          port: 80
  tls:
    certResolver: cloudflare
```

---

## Quick Tips

### 1. Multi-document YAML

Separate multiple resources with `---`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
---
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: my-app
```

### 2. Environment Variables from ConfigMap/Secret

```yaml
env:
  # From ConfigMap
  - name: CONFIG_VALUE
    valueFrom:
      configMapKeyRef:
        name: my-config
        key: CONFIG_VALUE
  
  # From Secret
  - name: SECRET_VALUE
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: SECRET_VALUE
  
  # Direct value
  - name: DIRECT_VALUE
    value: "my-value"
```

### 3. Labels and Selectors

Always match labels:

```yaml
# Deployment
spec:
  selector:
    matchLabels:
      app: my-app      # Must match template labels
  template:
    metadata:
      labels:
        app: my-app    # Must match selector

# Service
spec:
  selector:
    app: my-app        # Must match pod labels
```

### 4. Resource Limits

Set appropriate limits:

```yaml
resources:
  requests:      # Minimum guaranteed
    memory: "128Mi"
    cpu: "100m"
  limits:        # Maximum allowed
    memory: "256Mi"
    cpu: "500m"
```

### 5. Health Probes

Always include health checks:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## Validation

Validate your YAML:

```bash
# Check syntax
kubectl apply --dry-run=client -f myfile.yaml

# Validate without applying
kubectl apply --dry-run=server -f myfile.yaml

# Validate specific resource
kubectl create --dry-run=client -f myfile.yaml -o yaml
```

---

## Common Patterns

### Pattern 1: Database + Application

```yaml
# PostgreSQL + App
apps/
  my-app/
    namespace.yaml
    postgres-secret.yaml
    postgres-pvc.yaml
    postgres-deployment.yaml
    postgres-service.yaml
    app-deployment.yaml
    app-service.yaml
    ingressroute.yaml
```

### Pattern 2: Microservices

```yaml
# Multiple services
apps/
  my-system/
    namespace.yaml
    api-deployment.yaml
    api-service.yaml
    web-deployment.yaml
    web-service.yaml
    worker-deployment.yaml
    ingressroute-api.yaml
    ingressroute-web.yaml
```

### Pattern 3: Monitoring Stack

```yaml
# Prometheus + Grafana
apps/
  monitoring/
    namespace.yaml
    prometheus.yaml
    grafana.yaml
    alertmanager.yaml
    ingressroute-grafana.yaml
    ingressroute-prometheus.yaml
```

---

## More Information

- [AUTHENTIK-GUIDE.md](AUTHENTIK-GUIDE.md) - Authentication setup
- [GETTING-STARTED.md](GETTING-STARTED.md) - Quick start guide
- [FAQ.md](FAQ.md) - Common questions
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

---

**Need help?** Open a [GitHub Issue](https://github.com/ParadoxG2/skoxie-argo/issues)
