# Authentik Infrastructure

This directory contains the Kubernetes manifests for deploying Authentik as your identity provider and authentication gateway.

## 📁 Files

- `namespace.yaml` - Creates the authentik namespace
- `secret.yaml` - Contains Authentik secrets (PostgreSQL password, secret key, etc.)
- `postgresql.yaml` - PostgreSQL database deployment and service
- `redis.yaml` - Redis cache deployment and service
- `server.yaml` - Authentik server deployment and service
- `worker.yaml` - Authentik worker deployment for background tasks
- `ingressroute.yaml` - Traefik IngressRoute for accessing Authentik UI
- `middleware.yaml` - Traefik ForwardAuth middleware for protecting apps

## 🚀 Quick Start

1. **Update secrets** in `secret.yaml`:
   ```bash
   # Generate a secure secret key (minimum 50 characters)
   openssl rand -base64 50
   
   # Update the following in secret.yaml:
   # - POSTGRES_PASSWORD
   # - AUTHENTIK_SECRET_KEY
   # - AUTHENTIK_BOOTSTRAP_PASSWORD
   # - Email settings (optional)
   ```

2. **Update domain** (if not using woxie.xyz):
   ```bash
   # Replace woxie.xyz with your domain
   sed -i 's/woxie\.xyz/yourdomain.com/g' *.yaml
   ```

3. **Deploy**:
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f secret.yaml
   kubectl apply -f .
   ```

4. **Monitor deployment**:
   ```bash
   kubectl get pods -n authentik -w
   ```

5. **Access Authentik**:
   - URL: https://auth.woxie.xyz
   - Username: admin@woxie.xyz
   - Password: (from AUTHENTIK_BOOTSTRAP_PASSWORD)

## 🔧 Configuration

After deployment, configure Authentik for ForwardAuth:

1. Log in to the Authentik admin interface
2. Create a **Proxy Provider** (Forward Auth mode)
3. Create an **Application** and link it to the provider
4. Create an **Outpost** (use embedded outpost)

See [AUTHENTIK-GUIDE.md](../AUTHENTIK-GUIDE.md) for detailed setup instructions.

## 🔐 Protecting Applications

To protect your applications with Authentik, add the middleware to your IngressRoute:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-namespace
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

## 📊 Monitoring

```bash
# Check all components
kubectl get all -n authentik

# Check server logs
kubectl logs -n authentik -l component=server -f

# Check worker logs
kubectl logs -n authentik -l component=worker -f

# Check database
kubectl logs -n authentik -l app=postgresql -f
```

## 🔄 Updates

To update Authentik to a newer version:

1. Edit `server.yaml` and `worker.yaml`
2. Update the image tag: `ghcr.io/goauthentik/server:2024.X.X`
3. Apply the changes: `kubectl apply -f .`
4. Monitor the rollout: `kubectl rollout status deployment -n authentik`

## 🆘 Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod -n authentik <pod-name>

# Check logs
kubectl logs -n authentik <pod-name>
```

### Database connection issues

```bash
# Verify PostgreSQL is running
kubectl get pods -n authentik -l app=postgresql

# Test connection
kubectl exec -n authentik deployment/authentik-server -- \
  sh -c 'PGPASSWORD=$AUTHENTIK_POSTGRESQL__PASSWORD psql -h postgresql -U authentik -d authentik -c "SELECT 1"'
```

### Authentik not accessible

```bash
# Check IngressRoute
kubectl get ingressroute -n authentik

# Check certificate
kubectl get certificate -A | grep auth

# Check Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f
```

## 📚 Resources

- [Authentik Documentation](https://goauthentik.io/docs/)
- [AUTHENTIK-GUIDE.md](../AUTHENTIK-GUIDE.md) - Complete implementation guide
- [Authentik with Traefik](https://goauthentik.io/docs/providers/proxy/traefik)

## ⚠️ Security Notes

- **Change all default passwords** in `secret.yaml`
- **Generate a secure AUTHENTIK_SECRET_KEY** (minimum 50 characters)
- Consider using **Sealed Secrets** or **External Secrets Operator** for production
- Enable **MFA** for admin accounts
- Regularly **backup** PostgreSQL database
- Use a **managed database** for production deployments

---

For detailed configuration and advanced setup, see [AUTHENTIK-GUIDE.md](../AUTHENTIK-GUIDE.md)
