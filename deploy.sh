#!/bin/bash

# Quick Deployment Script for Skoxie ArgoCD

set -e

echo "======================================"
echo "Skoxie ArgoCD Deployment Script"
echo "======================================"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    echo "Please configure kubectl first"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"
echo ""

# Check if ArgoCD is installed
if ! kubectl get namespace argocd &> /dev/null; then
    echo "ArgoCD namespace not found. Would you like to install ArgoCD?"
    read -p "Install ArgoCD? (y/n): " install_argo
    
    if [ "$install_argo" = "y" ]; then
        echo "Installing ArgoCD..."
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        echo "Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
        
        echo ""
        echo "✅ ArgoCD installed successfully!"
        echo ""
        echo "ArgoCD admin password:"
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        echo ""
        echo ""
    else
        echo "Please install ArgoCD first"
        exit 1
    fi
else
    echo "✅ ArgoCD is already installed"
    echo ""
fi

# Check if configuration is done
if grep -q "YOUR_CLOUDFLARE_API_TOKEN" config/values.yaml; then
    echo "⚠️  Configuration not completed!"
    echo ""
    echo "Please run ./configure.sh first to set up your credentials"
    echo "Or manually edit the configuration files"
    exit 1
fi

echo "✅ Configuration appears to be set"
echo ""

# Deploy root application
echo "Deploying root application..."
kubectl apply -f root-app.yaml

echo ""
echo "✅ Root application deployed!"
echo ""

echo "Checking application status..."
sleep 5
kubectl get applications -n argocd

echo ""
echo "======================================"
echo "Deployment initiated successfully!"
echo "======================================"
echo ""
echo "Monitor deployment progress:"
echo "  kubectl get applications -n argocd -w"
echo ""
echo "Check specific application:"
echo "  kubectl get application <app-name> -n argocd"
echo ""
echo "Access services (once DNS propagates):"
echo "  - Traefik Dashboard: https://traefik.woxie.xyz"
echo "  - Whoami Demo: https://whoami.woxie.xyz"
echo "  - Hello World: https://hello.woxie.xyz"
echo "  - Pangolin Auth: https://auth.woxie.xyz"
echo ""
echo "For troubleshooting, see SETUP.md"
echo ""
