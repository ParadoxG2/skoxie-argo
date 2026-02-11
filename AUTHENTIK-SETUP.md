# Authentik Setup Guide

This guide explains how to configure and use Authentik as the identity provider for the woxie.xyz infrastructure.

## What is Authentik?

Authentik is a modern, open-source identity provider (IdP) that supports:
- OAuth2 and OpenID Connect (OIDC)
- SAML 2.0
- LDAP
- Forward authentication (for Traefik)
- Multi-factor authentication (MFA)
- Single Sign-On (SSO)
- User management and groups

## Architecture

Authentik in this setup consists of:
- **Authentik Server**: Main web interface and API (port 9000)
- **Authentik Worker**: Background tasks and workflows
- **PostgreSQL**: Database backend for storing user data, configurations, and policies
- **Redis**: Cache and message broker for improved performance

## Initial Setup

### 1. Update Secrets

Before deploying, update the credentials in `infrastructure/authentik/secret.yaml`:

```bash
# Generate secure random strings
POSTGRES_PASSWORD=$(openssl rand -base64 32)
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 32)
AUTHENTIK_BOOTSTRAP_PASSWORD=$(openssl rand -base64 16)
AUTHENTIK_BOOTSTRAP_TOKEN=$(openssl rand -base64 32)

# Update the secret file with these values
kubectl create secret generic authentik-secret \
  --namespace=authentik \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=POSTGRES_USER="authentik" \
  --from-literal=POSTGRES_DB="authentik" \
  --from-literal=AUTHENTIK_SECRET_KEY="$AUTHENTIK_SECRET_KEY" \
  --from-literal=AUTHENTIK_BOOTSTRAP_PASSWORD="$AUTHENTIK_BOOTSTRAP_PASSWORD" \
  --from-literal=AUTHENTIK_BOOTSTRAP_TOKEN="$AUTHENTIK_BOOTSTRAP_TOKEN" \
  --from-literal=REDIS_PASSWORD="" \
  --dry-run=client -o yaml > infrastructure/authentik/secret.yaml
```

### 2. Deploy Authentik

If using ArgoCD (recommended):
```bash
kubectl apply -f bootstrap/authentik-app.yaml
```

Or deploy manually:
```bash
kubectl apply -f infrastructure/authentik/
```

### 3. Wait for Deployment

```bash
# Check the status
kubectl get pods -n authentik

# Wait for all pods to be running
kubectl wait --for=condition=ready pod -l app=authentik-server -n authentik --timeout=300s
kubectl wait --for=condition=ready pod -l app=authentik-postgresql -n authentik --timeout=300s
kubectl wait --for=condition=ready pod -l app=authentik-redis -n authentik --timeout=300s
```

### 4. Access Authentik UI

Once deployed and DNS has propagated, access Authentik at: https://auth.woxie.xyz

Initial login:
- Username: `akadmin` (default Authentik bootstrap user)
- Password: Use the `AUTHENTIK_BOOTSTRAP_PASSWORD` from your secret

## Configuring Authentik for Forward Authentication

To protect your applications with Authentik, you need to:

### 1. Create an Application in Authentik

1. Log into Authentik at https://auth.woxie.xyz
2. Go to **Applications** → **Applications**
3. Click **Create**
4. Fill in:
   - Name: e.g., "Traefik Forward Auth"
   - Slug: e.g., "traefik-forwardauth"
   - Provider: Create a new **Proxy Provider**

### 2. Create a Proxy Provider

1. Go to **Applications** → **Providers**
2. Click **Create**
3. Select **Proxy Provider**
4. Configure:
   - Name: e.g., "Traefik Forward Auth Provider"
   - Authorization flow: default-provider-authorization-implicit-consent
   - Type: **Forward auth (single application)**
   - External host: `https://auth.woxie.xyz`
   - Cookie domain: `woxie.xyz`

### 3. Create an Outpost

1. Go to **Applications** → **Outposts**
2. Create or edit the **embedded outpost**
3. Add your proxy provider to the outpost
4. The embedded outpost runs within the Authentik server container

### 4. Protect Applications with Middleware

Add the `pangolin-auth` middleware to any IngressRoute to protect it:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-protected-app
  namespace: my-namespace
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
        - name: my-app-service
          port: 80
  tls:
    certResolver: cloudflare
```

## User Management

### Creating Users

1. Go to **Directory** → **Users**
2. Click **Create**
3. Fill in user details
4. Set a password or send an enrollment link

### Creating Groups

1. Go to **Directory** → **Groups**
2. Click **Create**
3. Add users to groups for easier management

### Setting Up MFA

1. Go to **Flows & Stages** → **Stages**
2. Create authenticator stages (TOTP, WebAuthn, etc.)
3. Add stages to authentication flows
4. Users can configure MFA in their user settings

## Advanced Configuration

### Customizing Authentication Flows

1. Go to **Flows & Stages** → **Flows**
2. Edit or create flows for:
   - Login
   - Enrollment (user registration)
   - Recovery (password reset)
   - Authorization

### Setting Up Social Logins

1. Go to **Directory** → **Federation & Social Login**
2. Add providers (Google, GitHub, GitLab, etc.)
3. Configure OAuth credentials from each provider

### Configuring Email

1. Go to **System** → **Tenants**
2. Edit the default tenant
3. Configure SMTP settings for email notifications

### Setting Up LDAP

1. Go to **Applications** → **Providers**
2. Create an **LDAP Provider**
3. Configure bind DN and search parameters
4. Applications can connect to Authentik's LDAP interface

## Troubleshooting

### Pods Not Starting

Check logs:
```bash
kubectl logs -n authentik -l app=authentik-server
kubectl logs -n authentik -l app=authentik-worker
kubectl logs -n authentik -l app=authentik-postgresql
```

### Database Connection Issues

Verify PostgreSQL is running:
```bash
kubectl get pods -n authentik -l app=authentik-postgresql
kubectl logs -n authentik -l app=authentik-postgresql
```

### Authentication Not Working

1. Check that the middleware is correctly configured
2. Verify the forward auth provider is assigned to an outpost
3. Check Authentik logs for authentication errors
4. Ensure cookie domain matches your domain (`.woxie.xyz`)

### Accessing Authentik Directly

If you need to access Authentik without going through Traefik:
```bash
kubectl port-forward -n authentik svc/authentik-server 9000:9000
# Access at http://localhost:9000
```

## Backup and Restore

### Backup PostgreSQL Database

```bash
# Export database
kubectl exec -n authentik deployment/authentik-postgresql -- \
  pg_dump -U authentik authentik > authentik-backup.sql

# Backup secrets
kubectl get secret authentik-secret -n authentik -o yaml > authentik-secret-backup.yaml
```

### Restore Database

```bash
# Copy backup to pod
kubectl cp authentik-backup.sql authentik/authentik-postgresql-POD:/tmp/

# Restore
kubectl exec -n authentik deployment/authentik-postgresql -- \
  psql -U authentik authentik < /tmp/authentik-backup.sql
```

## Monitoring

### Health Checks

Authentik provides health check endpoints:
- Liveness: `http://authentik-server:9000/-/health/live/`
- Readiness: `http://authentik-server:9000/-/health/ready/`

### Metrics

Authentik supports Prometheus metrics at:
- `http://authentik-server:9000/metrics`

## Security Best Practices

1. **Change Default Credentials**: Immediately change the bootstrap password after first login
2. **Enable MFA**: Require MFA for all admin accounts
3. **Use Strong Secrets**: Generate cryptographically secure random secrets
4. **Regular Backups**: Backup database and configuration regularly
5. **Update Regularly**: Keep Authentik updated to latest stable version
6. **Monitor Logs**: Regularly review authentication logs for suspicious activity
7. **Least Privilege**: Use groups and policies to enforce least privilege access

## Additional Resources

- [Authentik Official Documentation](https://goauthentik.io/docs/)
- [Authentik GitHub Repository](https://github.com/goauthentik/authentik)
- [Traefik Forward Auth Guide](https://goauthentik.io/integrations/services/traefik/)
- [Authentik API Documentation](https://goauthentik.io/api/)

## Migration from Pangolin

The existing `pangolin` namespace and middleware have been updated to use Authentik:
- The `pangolin-auth` middleware now points to Authentik's forward auth endpoint
- All existing applications using this middleware will automatically use Authentik
- The old traefik-forward-auth deployment is no longer needed and can be removed

To complete the migration:
1. Set up applications in Authentik as described above
2. Test authentication with your applications
3. Once verified, you can remove the old pangolin deployment (but keep the middleware)

```bash
# Remove old deployment (optional, after testing)
kubectl delete deployment pangolin -n pangolin
kubectl delete service pangolin -n pangolin
kubectl delete configmap pangolin-config -n pangolin
kubectl delete secret pangolin-secret -n pangolin
```
