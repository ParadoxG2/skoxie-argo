# Authentik Quick Reference

## Protecting an Application

To add authentication to your application, add the middleware to your IngressRoute:

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
        - name: pangolin-auth      # The authentication middleware
          namespace: pangolin       # Must reference pangolin namespace
      services:
        - name: my-app-service
          port: 80
  tls:
    certResolver: cloudflare
```

## Useful Commands

### Check Authentik Status
```bash
kubectl get pods -n authentik
kubectl get svc -n authentik
```

### View Authentik Logs
```bash
# Server logs
kubectl logs -n authentik -l app=authentik-server -f

# Worker logs
kubectl logs -n authentik -l app=authentik-worker -f

# Database logs
kubectl logs -n authentik -l app=authentik-postgresql -f
```

### Access Authentik UI
```bash
# Via ingress (production)
https://auth.woxie.xyz

# Via port-forward (troubleshooting)
kubectl port-forward -n authentik svc/authentik-server 9000:9000
# Then access: http://localhost:9000
```

### Generate Secure Secrets
```bash
# For secret generation
openssl rand -base64 32

# Update all secrets at once
kubectl create secret generic authentik-secret \
  --namespace=authentik \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -base64 32)" \
  --from-literal=POSTGRES_USER="authentik" \
  --from-literal=POSTGRES_DB="authentik" \
  --from-literal=AUTHENTIK_SECRET_KEY="$(openssl rand -base64 50)" \
  --from-literal=AUTHENTIK_BOOTSTRAP_PASSWORD="$(openssl rand -base64 16)" \
  --from-literal=AUTHENTIK_BOOTSTRAP_TOKEN="$(openssl rand -base64 32)" \
  --from-literal=REDIS_PASSWORD="" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Database Backup
```bash
# Backup database
kubectl exec -n authentik deployment/authentik-postgresql -- \
  pg_dump -U authentik authentik > authentik-backup-$(date +%Y%m%d).sql

# Restore database
kubectl exec -n authentik deployment/authentik-postgresql -i -- \
  psql -U authentik authentik < authentik-backup-YYYYMMDD.sql
```

### Restart Services
```bash
# Restart server
kubectl rollout restart deployment/authentik-server -n authentik

# Restart worker
kubectl rollout restart deployment/authentik-worker -n authentik

# Restart database (use with caution)
kubectl rollout restart deployment/authentik-postgresql -n authentik
```

## Common Tasks in Authentik UI

### Create a User
1. Navigate to **Directory** → **Users**
2. Click **Create**
3. Fill in user details
4. Set password or send enrollment invitation

### Create an Application
1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Configure application settings
4. Assign a provider

### Set Up Forward Auth Provider
1. Navigate to **Applications** → **Providers**
2. Click **Create** → **Proxy Provider**
3. Select **Forward auth (single application)**
4. Configure:
   - External host: `https://auth.woxie.xyz`
   - Cookie domain: `woxie.xyz`
5. Assign to embedded outpost

### Enable MFA for a User
1. Navigate to **Directory** → **Users**
2. Select user
3. Go to **User settings** → **MFA Devices**
4. Add authenticator (TOTP, WebAuthn, etc.)

### View Authentication Logs
1. Navigate to **Events** → **Logs**
2. Filter by event type (login, failed login, etc.)
3. Review user activity and troubleshoot issues

## Troubleshooting

### Authentication Loop
- Check forward auth provider configuration
- Verify cookie domain is set to `.woxie.xyz`
- Ensure application is assigned to outpost
- Check Traefik middleware configuration

### Users Can't Login
- Verify user is active (not suspended)
- Check authentication flow is correct
- Review event logs for specific errors
- Verify user has access to the application

### Database Connection Errors
- Check PostgreSQL pod is running
- Verify credentials in secret
- Check network connectivity between pods

### Performance Issues
- Check Redis is running and connected
- Review worker logs for task backlog
- Consider scaling server/worker replicas
- Check database performance

## Security Checklist

- [ ] Changed default bootstrap password
- [ ] Generated secure random secrets
- [ ] Enabled MFA for admin accounts
- [ ] Configured email notifications
- [ ] Set up regular database backups
- [ ] Reviewed and customized authentication flows
- [ ] Configured session timeouts appropriately
- [ ] Set up monitoring and alerts
- [ ] Reviewed user access and permissions
- [ ] Enabled audit logging

## Resources

- 📖 Full Setup Guide: [AUTHENTIK-SETUP.md](AUTHENTIK-SETUP.md)
- 🌐 Authentik Documentation: https://goauthentik.io/docs/
- 🔧 API Documentation: https://goauthentik.io/api/
- 🚀 GitHub Repository: https://github.com/goauthentik/authentik
- 💬 Community Discord: https://goauthentik.io/discord
