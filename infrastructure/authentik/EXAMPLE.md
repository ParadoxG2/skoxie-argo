# Example: Protected Application with Authentik

This example shows how to protect an application using Authentik authentication.

## Example: Whoami App with Authentik

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-apps
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami-protected
  namespace: secure-apps
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami-protected
  template:
    metadata:
      labels:
        app: whoami-protected
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami-protected
  namespace: secure-apps
spec:
  selector:
    app: whoami-protected
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: whoami-protected
  namespace: secure-apps
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`secure.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: whoami-protected
          port: 80
  tls:
    certResolver: cloudflare
```

## Key Points

### 1. Add Middleware Reference

```yaml
middlewares:
  - name: authentik        # Name of the middleware
    namespace: authentik   # Namespace where Authentik is deployed
```

This tells Traefik to use Authentik's ForwardAuth middleware for authentication.

### 2. Authentication Flow

When a user accesses `https://secure.woxie.xyz`:

1. **Traefik** receives the request
2. **Traefik** checks the `authentik` middleware
3. **Authentik** checks if the user is authenticated
4. If **not authenticated**: Redirect to Authentik login page
5. If **authenticated**: Forward request to the application
6. User sees the protected application

### 3. User Information

Authentik passes user information to your app via headers:

- `X-authentik-username` - Username
- `X-authentik-email` - Email address
- `X-authentik-groups` - User groups
- `X-authentik-name` - Full name
- `X-authentik-uid` - User ID

Your application can read these headers to know who the user is.

## Example: Multiple Protected Apps

```yaml
# App 1: Grafana
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: grafana
  namespace: monitoring
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`grafana.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: grafana
          port: 3000
  tls:
    certResolver: cloudflare

# App 2: ArgoCD
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: argocd
  namespace: argocd
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`argocd.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: argocd-server
          port: 80
  tls:
    certResolver: cloudflare

# App 3: Prometheus
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: prometheus
  namespace: monitoring
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`prometheus.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: prometheus
          port: 9090
  tls:
    certResolver: cloudflare
```

## Public vs Protected Apps

### Public App (No Authentication)

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: public-app
  namespace: public
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`public.woxie.xyz`)
      kind: Rule
      # No middlewares = no authentication
      services:
        - name: public-app
          port: 80
  tls:
    certResolver: cloudflare
```

### Protected App (With Authentication)

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: protected-app
  namespace: protected
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`protected.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: authentik
          namespace: authentik
      services:
        - name: protected-app
          port: 80
  tls:
    certResolver: cloudflare
```

## Advanced: Group-Based Access

You can configure Authentik to allow only specific groups:

1. In Authentik, create a **Policy** that checks user groups
2. Attach the policy to your application
3. Only users in specified groups can access

Example groups:
- `admins` - Full access to all apps
- `developers` - Access to development tools
- `users` - Access to general apps

## Testing

1. **Deploy the example**:
   ```bash
   kubectl apply -f example-protected-app.yaml
   ```

2. **Wait for deployment**:
   ```bash
   kubectl get pods -n secure-apps
   ```

3. **Access the app**:
   - Open: https://secure.woxie.xyz
   - You should be redirected to Authentik login
   - After login, you'll see the whoami app
   - The app will show your user information in headers

## Troubleshooting

### "Too Many Redirects" Error

This usually means the middleware is not configured correctly.

**Check**:
```bash
# Verify middleware exists
kubectl get middleware -n authentik

# Check middleware configuration
kubectl describe middleware authentik -n authentik
```

### Authentication Not Working

**Check**:
```bash
# Check Authentik server is running
kubectl get pods -n authentik

# Check Authentik logs
kubectl logs -n authentik -l component=server -f

# Check Traefik can reach Authentik
kubectl exec -n traefik deployment/traefik -- \
  wget -O- http://authentik-server.authentik.svc.cluster.local:9000/-/health/live/
```

### Users Can't Log In

**Check**:
1. Verify user exists in Authentik
2. Check user is active
3. Verify application is configured in Authentik
4. Check Outpost is running

## Next Steps

1. ✅ Deploy a protected application
2. ✅ Test authentication flow
3. ✅ Configure MFA in Authentik
4. ✅ Add external OAuth providers (Google, GitHub)
5. ✅ Create user groups and policies
6. ✅ Protect all your applications

---

For more information, see [AUTHENTIK-GUIDE.md](../AUTHENTIK-GUIDE.md)
