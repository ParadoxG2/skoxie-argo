#!/bin/bash

# Configuration Helper Script for Skoxie ArgoCD
# This script helps you configure all secrets easily

set -e

echo "======================================"
echo "Skoxie ArgoCD Configuration Helper"
echo "======================================"
echo ""

# Check if running in correct directory
if [ ! -f "root-app.yaml" ]; then
    echo "Error: Please run this script from the repository root directory"
    exit 1
fi

echo "This script will help you configure all required secrets."
echo "Your credentials will ONLY be saved to the repository files."
echo ""

# Get Cloudflare Email
read -p "Enter your Cloudflare email: " CF_EMAIL

# Get Cloudflare API Token
echo ""
echo "Enter your Cloudflare API Token"
echo "(Create one at: https://dash.cloudflare.com/profile/api-tokens)"
read -s -p "Cloudflare API Token: " CF_API_TOKEN
echo ""

# Get Let's Encrypt Email
echo ""
read -p "Enter your email for Let's Encrypt certificates (can be same as above): " LE_EMAIL

# Generate session secret for Pangolin
echo ""
echo "Generating secure session secret for Pangolin..."
PANGOLIN_SECRET=$(openssl rand -base64 32)

echo ""
echo "Updating configuration files..."

# Update config/values.yaml
sed -i.bak "s/YOUR_CLOUDFLARE_API_TOKEN/$CF_API_TOKEN/g" config/values.yaml
sed -i.bak "s/YOUR_EMAIL@example.com/$CF_EMAIL/g" config/values.yaml

# Update Traefik
sed -i.bak "s/YOUR_EMAIL@example.com/$CF_EMAIL/g" infrastructure/traefik/cloudflare-secret.yaml
sed -i.bak "s/YOUR_CLOUDFLARE_API_TOKEN/$CF_API_TOKEN/g" infrastructure/traefik/cloudflare-secret.yaml
sed -i.bak "s/YOUR_EMAIL@example.com/$LE_EMAIL/g" infrastructure/traefik/helm-release.yaml

# Update cert-manager
sed -i.bak "s/YOUR_CLOUDFLARE_API_TOKEN/$CF_API_TOKEN/g" infrastructure/cert-manager/cloudflare-secret.yaml
sed -i.bak "s/YOUR_EMAIL@example.com/$LE_EMAIL/g" infrastructure/cert-manager/cluster-issuer-production.yaml
sed -i.bak "s/YOUR_EMAIL@example.com/$LE_EMAIL/g" infrastructure/cert-manager/cluster-issuer-staging.yaml

# Update Cloudflare DDNS
sed -i.bak "s/YOUR_CLOUDFLARE_API_TOKEN/$CF_API_TOKEN/g" infrastructure/cloudflare-ddns/secret.yaml

# Update Pangolin
sed -i.bak "s/CHANGE_THIS_TO_A_SECURE_RANDOM_STRING/$PANGOLIN_SECRET/g" infrastructure/pangolin/secret.yaml

# Remove backup files
find . -name "*.bak" -delete

echo ""
echo "✅ Configuration completed successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit the changes: git add . && git commit -m 'Configure secrets'"
echo "3. Push to repository: git push"
echo "4. Deploy: kubectl apply -f root-app.yaml"
echo ""
echo "⚠️  IMPORTANT: Your secrets are now in the repository."
echo "    Consider using Sealed Secrets or External Secrets Operator for production."
echo ""
