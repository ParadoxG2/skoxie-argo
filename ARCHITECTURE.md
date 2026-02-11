# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet (woxie.xyz)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                   ┌─────────────────────┐
                   │   Cloudflare DNS    │
                   │  (DDNS Updated)     │
                   └──────────┬──────────┘
                              │
                              ▼
                   ┌─────────────────────┐
                   │   LoadBalancer IP   │
                   │  (Traefik Service)  │
                   └──────────┬──────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                           │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  Traefik (Namespace: traefik)                ││
│  │  • Ingress Controller                                        ││
│  │  • TLS Termination (Let's Encrypt)                          ││
│  │  • Routes traffic to services                                ││
│  │  • Dashboard: traefik.woxie.xyz                             ││
│  └────────────────────────┬─────────────────────────────────────┘│
│                            │                                      │
│           ┌────────────────┼────────────────┬─────────────────┐  │
│           │                │                │                 │  │
│           ▼                ▼                ▼                 ▼  │
│  ┌────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────┐│
│  │   Authentik    │ │  Demo Apps   │ │   ArgoCD     │ │  Your  ││
│  │ (auth.woxie)   │ │(whoami/hello)│ │(argocd.woxie)│ │  Apps  ││
│  └────────────────┘ └──────────────┘ └──────────────┘ └─────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │              cert-manager (Namespace: cert-manager)          ││
│  │  • Manages SSL/TLS Certificates                              ││
│  │  • Let's Encrypt Integration                                 ││
│  │  • Cloudflare DNS-01 Challenge                              ││
│  │  • Auto-renewal of certificates                              ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │         Cloudflare DDNS (Namespace: cloudflare-ddns)         ││
│  │  • Updates DNS records automatically                         ││
│  │  • Monitors external IP changes                              ││
│  │  • Updates @ and * records                                   ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                ArgoCD (Namespace: argocd)                     ││
│  │  • GitOps Continuous Delivery                                ││
│  │  • Monitors Git repository                                   ││
│  │  • Auto-syncs applications                                   ││
│  │  • Manages all deployments                                   ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Component Interactions

### 1. Traffic Flow

```
User Request → Cloudflare DNS → LoadBalancer → Traefik → Service → Pod
```

**Example**: User visits `whoami.woxie.xyz`
1. DNS resolves to LoadBalancer IP (via DDNS)
2. Request hits Traefik on port 443
3. Traefik terminates TLS using Let's Encrypt certificate
4. Traefik routes to whoami service based on Host header
5. Service forwards to whoami pod
6. Response returns through same path

### 2. Certificate Management Flow

```
cert-manager → Let's Encrypt → Cloudflare DNS-01 Challenge → Certificate Issued
```

**Process**:
1. cert-manager creates certificate request
2. Let's Encrypt responds with DNS-01 challenge
3. cert-manager creates TXT record in Cloudflare
4. Let's Encrypt verifies DNS record
5. Certificate is issued and stored as Kubernetes secret
6. Traefik uses the certificate for TLS termination

### 3. GitOps Flow

```
Git Push → GitHub → ArgoCD Detects Change → ArgoCD Syncs → Kubernetes Updated
```

**Process**:
1. Developer pushes changes to Git
2. ArgoCD polls repository (or webhook triggers)
3. ArgoCD detects differences between Git and cluster
4. ArgoCD applies changes to cluster
5. Applications are updated automatically

### 4. DDNS Update Flow

```
DDNS Pod → Detects IP → Cloudflare API → DNS Records Updated
```

**Process**:
1. DDNS pod checks external IP (via ipify.org)
2. Compares with Cloudflare DNS records
3. If different, updates via Cloudflare API
4. Runs every 5 minutes (configurable)

## Network Architecture

### Ingress (External Access)
- **Port 80**: HTTP (redirects to 443)
- **Port 443**: HTTPS (TLS termination)

### Services (Internal)
- **Traefik**: ClusterIP for dashboard, LoadBalancer for ingress
- **Authentik**: ClusterIP:9000 (HTTP), ClusterIP:9443 (HTTPS)
- **PostgreSQL**: ClusterIP:5432 (Authentik backend)
- **Redis**: ClusterIP:6379 (Authentik cache)
- **Apps**: ClusterIP (various ports)
- **ArgoCD**: ClusterIP for UI

### Namespaces
- `argocd`: ArgoCD components
- `traefik`: Traefik ingress controller
- `cert-manager`: Certificate management
- `cloudflare-ddns`: DDNS updater
- `authentik`: Authentik identity provider
- `pangolin`: Authentication middleware (references Authentik)
- `demo-apps`: Example applications
- *(Your app namespaces)*

## Security Architecture

### TLS/SSL
- **Certificates**: Wildcard certificate for `*.woxie.xyz`
- **Issuer**: Let's Encrypt (production/staging)
- **Validation**: DNS-01 challenge via Cloudflare
- **Storage**: Kubernetes secrets in each namespace
- **Renewal**: Automatic via cert-manager

### Authentication
- **Authentik**: Modern identity provider with OAuth2, SAML, LDAP support
- **ForwardAuth**: Traefik middleware integration
- **Session**: Cookie-based sessions with Redis cache
- **Domain**: `.woxie.xyz` (all subdomains)
- **MFA**: Multi-factor authentication support
- **SSO**: Single Sign-On across all applications

### Secrets Management
- **Cloudflare API Token**: Multiple secrets in different namespaces
- **Authentik Credentials**: PostgreSQL, Redis, and bootstrap passwords
- **Session Secrets**: Authentik namespace
- **Certificates**: Auto-generated by cert-manager

**Current**: Plain Kubernetes secrets (not encrypted at rest in Git)
**Recommendation**: Use Sealed Secrets or External Secrets Operator for production

## Data Flow Diagrams

### Application Deployment

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│Developer │────▶│   Git    │────▶│  ArgoCD  │────▶│Kubernetes│
└──────────┘     └──────────┘     └──────────┘     └──────────┘
   Commit          Push             Sync            Deploy
```

### Certificate Issuance

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│cert-manager  │────▶│Let's Encrypt │────▶│  Cloudflare  │
└──────────────┘     └──────────────┘     └──────────────┘
  Certificate           Challenge           DNS Record
   Request               Created             Created
      │                     │                    │
      └─────────────────────┴────────────────────┘
                    Certificate Issued
```

### Authentication Flow

```
┌──────┐     ┌─────────┐     ┌──────────┐     ┌────────────┐
│ User │────▶│ Traefik │────▶│Authentik │────▶│   IdP/     │
└──────┘     └─────────┘     └──────────┘     └────────────┘
  Request      Forward         Verify           Authenticate
               Auth            Session
    │             │               │                   │
    └─────────────┴───────────────┴───────────────────┘
                    Session Cookie Set
    │
    ▼
┌─────────┐
│   App   │
└─────────┘
```

## Scalability

### Current Setup
- **Traefik**: 1 replica (can scale horizontally)
- **cert-manager**: 1 replica per component
- **DDNS**: 1 replica per record type
- **Authentik Server**: 1 replica (can scale horizontally)
- **Authentik Worker**: 1 replica (can scale horizontally)
- **PostgreSQL**: 1 replica (stateful, consider HA setup)
- **Redis**: 1 replica (can add sentinel for HA)
- **ArgoCD**: Default installation (can be HA)

### Scaling Considerations
1. **Traefik**: Can scale to multiple replicas behind LoadBalancer
2. **Applications**: Scale based on load (HPA recommended)
3. **cert-manager**: Single instance sufficient (not compute-intensive)
4. **DDNS**: One replica per DNS record (no need to scale)

## High Availability

### Implemented
- ✅ Authentik: Server and worker for HA
- ✅ Demo apps: 2 replicas
- ✅ Traefik: Persistence for ACME certificates
- ✅ PostgreSQL: Persistent storage for Authentik data
- ✅ Redis: Persistent storage for session cache

### To Implement
- ⏸ ArgoCD HA mode
- ⏸ Multiple Traefik replicas
- ⏸ Database backup strategy
- ⏸ Multi-region setup

## Monitoring Points

### Recommended Metrics
1. **Traefik**: Request rate, error rate, latency
2. **cert-manager**: Certificate expiration dates
3. **DDNS**: Update success/failure rate
4. **ArgoCD**: Sync status, health status
5. **Applications**: Custom application metrics

### Recommended Alerts
1. Certificate expiring in < 7 days
2. DDNS update failures
3. ArgoCD sync failures
4. Application unhealthy status
5. High error rates in Traefik

## Backup Strategy

### What to Backup
1. **Git Repository**: Primary source of truth (already backed up by GitHub)
2. **Secrets**: Export and encrypt separately
3. **ArgoCD Configuration**: Export ArgoCD applications and projects
4. **Persistent Volumes**: If applications use PVs

### Backup Commands
```bash
# Export all ArgoCD applications
argocd app list -o yaml > argocd-apps-backup.yaml

# Export all secrets (encrypt before storing!)
kubectl get secrets -A -o yaml > secrets-backup.yaml

# Export all certificates
kubectl get certificates -A -o yaml > certificates-backup.yaml
```

## Disaster Recovery

### Recovery Steps
1. **New Cluster**: Install ArgoCD
2. **Deploy Root App**: `kubectl apply -f root-app.yaml`
3. **Configure Secrets**: Run `./configure.sh`
4. **Wait for Sync**: ArgoCD will restore everything from Git
5. **Verify**: Check all applications are healthy

### RTO/RPO
- **RTO** (Recovery Time Objective): ~15 minutes
- **RPO** (Recovery Point Objective): Minutes (Git commit frequency)

## Technology Stack

### Core Components
- **Kubernetes**: Container orchestration
- **ArgoCD**: GitOps continuous delivery
- **Traefik**: Ingress controller and API gateway
- **cert-manager**: Certificate management
- **Let's Encrypt**: Free SSL/TLS certificates
- **Cloudflare**: DNS and API

### Container Images
- `traefik:latest` (Traefik official)
- `jetstack/cert-manager` (cert-manager official)
- `oznu/cloudflare-ddns` (DDNS updater)
- `ghcr.io/goauthentik/server:2024.2.2` (Authentik server and worker)
- `postgres:16-alpine` (PostgreSQL for Authentik)
- `redis:7-alpine` (Redis for Authentik cache)
- Various app images (nginx, whoami, etc.)

## Future Enhancements

### Short-term
- [ ] Add monitoring (Prometheus + Grafana)
- [ ] Implement Sealed Secrets
- [ ] Add backup automation
- [ ] Create more example applications

### Long-term
- [ ] Multi-cluster support
- [ ] Service mesh (Istio/Linkerd)
- [ ] Policy enforcement (OPA)
- [ ] Cost optimization
- [ ] Advanced observability
