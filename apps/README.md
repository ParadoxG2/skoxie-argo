# Example Applications

This directory contains example applications that demonstrate how to deploy apps with this ArgoCD setup.

## Available Examples

1. **Hello World App** - Simple demo application
2. **Whoami App** - Useful for testing Traefik routing and headers

## Adding Your Own Apps

To add your own application:

1. Create a new directory under `apps/`
2. Add your Kubernetes manifests (Deployment, Service, IngressRoute, etc.)
3. Create an Application manifest in this directory
4. ArgoCD will automatically detect and deploy your app

## Example App Structure

```
apps/
├── your-app/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingressroute.yaml
└── your-app-application.yaml
```

## Using Pangolin Authentication

To add authentication to your app, add the Pangolin middleware to your IngressRoute:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: your-app
  namespace: your-namespace
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`your-app.woxie.xyz`)
      kind: Rule
      middlewares:
        - name: pangolin-auth
          namespace: pangolin
      services:
        - name: your-app
          port: 80
  tls:
    certResolver: cloudflare
```
