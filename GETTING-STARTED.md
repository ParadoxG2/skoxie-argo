# Getting Started with Skoxie ArgoCD

Welcome! This guide will help you get your ArgoCD-based Kubernetes infrastructure up and running in under 30 minutes.

## 📋 What You'll Get

After following this guide, you'll have:

- ✅ **Traefik** - Production-ready ingress controller
- ✅ **cert-manager** - Automated SSL/TLS certificates from Let's Encrypt
- ✅ **Cloudflare DDNS** - Automatic DNS updates for your domain
- ✅ **Pangolin Auth** - Authentication gateway for securing apps
- ✅ **ArgoCD** - GitOps continuous delivery
- ✅ **Example Apps** - Working demo applications
- ✅ **Easy Configuration** - Simple YAML-based setup

All managed through GitOps with ArgoCD!

## 🎯 Prerequisites

Before starting, make sure you have:

### Required
- [ ] Kubernetes cluster (v1.24 or newer)
- [ ] `kubectl` installed and configured
- [ ] Cloudflare account
- [ ] Domain name (we use woxie.xyz)

### Recommended
- [ ] `git` installed
- [ ] Basic Kubernetes knowledge
- [ ] 30 minutes of your time

### Optional
- [ ] `argocd` CLI tool
- [ ] Helm installed

## 🚀 Quick Start (5 Commands)

If you're experienced and want to get started immediately:

```bash
# 1. Clone repository
git clone https://github.com/ParadoxG2/skoxie-argo.git
cd skoxie-argo

# 2. Install ArgoCD (if needed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Configure secrets
./configure.sh

# 4. Deploy everything
./deploy.sh

# 5. Watch deployment
kubectl get applications -n argocd -w
```

That's it! For detailed explanations, continue reading.

## 📝 Detailed Setup

### Step 1: Prepare Your Cluster

**Create or Access a Kubernetes Cluster:**

<details>
<summary>Using Minikube (Local Testing)</summary>

```bash
minikube start --cpus=4 --memory=8192
minikube addons enable ingress
```
</details>

<details>
<summary>Using Kind (Local Testing)</summary>

```bash
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
EOF
```
</details>

<details>
<summary>Using Cloud Provider</summary>

**GKE:**
```bash
gcloud container clusters create my-cluster --num-nodes=3
```

**EKS:**
```bash
eksctl create cluster --name my-cluster --nodes=3
```

**AKS:**
```bash
az aks create --resource-group myResourceGroup --name myCluster --node-count 3
```
</details>

**Verify Connection:**
```bash
kubectl cluster-info
kubectl get nodes
```

### Step 2: Get Cloudflare Credentials

**Create API Token:**

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use **Edit zone DNS** template or create custom with:
   - Permissions: `Zone.DNS` (Edit), `Zone.Zone` (Read)
   - Zone Resources: Include → Specific zone → `woxie.xyz`
5. Click **Continue to summary** → **Create Token**
6. **Copy the token** (you won't see it again!)

**What You Need:**
- Cloudflare API Token (just created)
- Cloudflare Email (your login email)

### Step 3: Clone Repository

```bash
# Clone the repository
git clone https://github.com/ParadoxG2/skoxie-argo.git
cd skoxie-argo

# Check the structure
ls -la
```

You should see:
- `bootstrap/` - ArgoCD applications
- `infrastructure/` - Infrastructure components
- `apps/` - Example applications
- `config/` - Configuration files
- Scripts and documentation

### Step 4: Install ArgoCD

**Check if ArgoCD is already installed:**
```bash
kubectl get namespace argocd
```

**If not installed:**
```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready (2-5 minutes)
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Success!
echo "✅ ArgoCD installed successfully"
```

**Get ArgoCD admin password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
```

Save this password - you'll need it to access the ArgoCD UI!

### Step 5: Configure Secrets

**Interactive Configuration (Recommended):**
```bash
./configure.sh
```

This script will prompt you for:
- Cloudflare email
- Cloudflare API token
- Let's Encrypt email

**Manual Configuration:**

If you prefer to edit files manually:

1. **Update `config/values.yaml`:**
```yaml
cloudflare:
  apiToken: "your_actual_token_here"
  email: "your_email@example.com"

certManager:
  email: "your_email@example.com"
```

2. **Update secrets in each infrastructure component:**
   - `infrastructure/traefik/cloudflare-secret.yaml`
   - `infrastructure/cert-manager/cloudflare-secret.yaml`
   - `infrastructure/cloudflare-ddns/secret.yaml`

3. **Generate Pangolin session secret:**
```bash
openssl rand -base64 32
# Copy output to infrastructure/pangolin/secret.yaml
```

### Step 6: Deploy Everything

**Automated Deployment:**
```bash
./deploy.sh
```

**Manual Deployment:**
```bash
kubectl apply -f root-app.yaml
```

**What This Does:**
- Deploys the root ArgoCD application
- ArgoCD automatically deploys all infrastructure components
- Components self-configure and start running

### Step 7: Monitor Deployment

**Watch application status:**
```bash
kubectl get applications -n argocd -w
```

Wait until all show:
- **SYNC STATUS**: Synced
- **HEALTH STATUS**: Healthy

This typically takes 10-15 minutes.

**Check individual components:**
```bash
# Traefik
kubectl get pods -n traefik

# cert-manager
kubectl get pods -n cert-manager

# Cloudflare DDNS
kubectl get pods -n cloudflare-ddns

# Pangolin
kubectl get pods -n pangolin

# Example apps
kubectl get pods -n demo-apps
```

### Step 8: Wait for Certificates

Certificates can take 2-5 minutes to issue:

```bash
# Watch certificate status
kubectl get certificates -A -w

# When ready, you'll see:
# NAMESPACE   NAME                  READY   SECRET           AGE
# traefik     woxie-xyz-wildcard   True    woxie-xyz-tls   3m
```

**If certificates are stuck:**
```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Verify Cloudflare secret
kubectl get secret cloudflare-api-token-secret -n cert-manager -o yaml
```

### Step 9: Configure DNS

**Option A: Automatic (DDNS)**

The Cloudflare DDNS updater will automatically:
- Detect your external IP
- Update DNS records
- Keep records in sync

Wait 5-10 minutes for initial update.

**Option B: Manual**

If you have a static IP:

```bash
# Get your LoadBalancer IP
kubectl get svc -n traefik traefik

# Add these records in Cloudflare:
# Type  Name  Content          Proxy
# A     @     YOUR_IP_HERE     DNS only
# A     *     YOUR_IP_HERE     DNS only
```

### Step 10: Verify Everything Works

**Check DNS resolution:**
```bash
nslookup traefik.woxie.xyz
nslookup whoami.woxie.xyz
```

**Access services:**
```bash
# Test with curl
curl https://whoami.woxie.xyz
curl https://hello.woxie.xyz

# Or open in browser:
# https://traefik.woxie.xyz - Traefik Dashboard
# https://whoami.woxie.xyz - Whoami Demo
# https://hello.woxie.xyz - Hello World Demo
```

**Check ArgoCD UI:**
```bash
# Option 1: Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access at: https://localhost:8080
# Username: admin
# Password: (from Step 4)

# Option 2: Create ingress (see SETUP.md)
```

## 🎉 Success!

You now have a fully functional GitOps infrastructure! 

## 🔄 What's Next?

### Add Your Own Application

1. **Create app manifests:**
```bash
mkdir -p apps/myapp
```

2. **Add deployment:**
```yaml
# apps/myapp/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 80
```

3. **Add service and ingress:**
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: myapp
spec:
  ports:
  - port: 80
  selector:
    app: myapp
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
  namespace: myapp
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myapp.woxie.xyz`)
      kind: Rule
      services:
        - name: myapp
          port: 80
  tls:
    certResolver: cloudflare
```

4. **Commit and push:**
```bash
git add apps/myapp/
git commit -m "Add myapp"
git push
```

5. **ArgoCD syncs automatically!**
```bash
kubectl get applications -n argocd
```

### Enable Authentication

Add Pangolin middleware to protect your app:

```yaml
spec:
  routes:
    - match: Host(`myapp.woxie.xyz`)
      middlewares:
        - name: pangolin-auth
          namespace: pangolin
      # ... rest of route
```

### Set Up Monitoring

Consider adding:
- Prometheus for metrics
- Grafana for visualization
- Alertmanager for alerts

### Production Hardening

Before production:
- [ ] Use Sealed Secrets for secret management
- [ ] Enable ArgoCD HA mode
- [ ] Set up backups
- [ ] Configure resource limits
- [ ] Add network policies
- [ ] Set up monitoring and alerting
- [ ] Document runbooks

## 📚 Learn More

- [README.md](README.md) - Full documentation
- [SETUP.md](SETUP.md) - Detailed setup guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [FAQ.md](FAQ.md) - Common questions
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Command reference

## 🆘 Troubleshooting

### Certificates Not Issuing

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Common issues:
# - Wrong API token
# - Insufficient permissions
# - Rate limiting (use staging)
```

### Applications Not Syncing

```bash
# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force sync
argocd app sync root-app
```

### DNS Not Resolving

```bash
# Check DDNS logs
kubectl logs -n cloudflare-ddns -l app=cloudflare-ddns -f

# Verify Cloudflare DNS records
# Check at: https://dash.cloudflare.com/
```

### Need Help?

- Check [FAQ.md](FAQ.md)
- Search [GitHub Issues](https://github.com/ParadoxG2/skoxie-argo/issues)
- Open a new issue
- Ask in discussions

## 🎯 Quick Commands Reference

```bash
# Check everything
kubectl get all -A

# Watch applications
kubectl get applications -n argocd -w

# Check certificates
kubectl get certificates -A

# View logs
kubectl logs -n <namespace> <pod-name> -f

# Restart component
kubectl rollout restart deployment <name> -n <namespace>

# Force sync
argocd app sync <app-name>
```

## 🏆 You Did It!

Congratulations! You've successfully set up a production-ready Kubernetes infrastructure with GitOps. 

**Share your success:**
- Star the repository ⭐
- Share with your team
- Contribute improvements
- Help others in discussions

---

**Happy GitOps!** 🚀

For questions or issues, open a [GitHub Issue](https://github.com/ParadoxG2/skoxie-argo/issues).
