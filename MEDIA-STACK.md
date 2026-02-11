# Media Stack Deployment Summary

## Overview

A complete media automation stack has been configured for the Skoxie-Argo repository with the following services:

## Services Deployed

### 1. **Prowlarr** - Indexer Manager
- **URL**: https://prowlarr.woxie.xyz
- **Purpose**: Central indexer management for all *arr applications
- **Storage**: 1Gi config volume

### 2. **Sonarr** - TV Show Management
- **URL**: https://sonarr.woxie.xyz
- **Purpose**: Automate TV show downloads and management
- **Storage**: 2Gi config, 100Gi TV library (shared), 100Gi downloads (shared)

### 3. **Radarr** - Movie Management
- **URL**: https://radarr.woxie.xyz
- **Purpose**: Automate movie downloads and management
- **Storage**: 2Gi config, 100Gi movie library (shared), 100Gi downloads (shared)

### 4. **Lidarr** - Music Management
- **URL**: https://lidarr.woxie.xyz
- **Purpose**: Automate music downloads and management
- **Storage**: 2Gi config, 50Gi music library (shared), 100Gi downloads (shared)

### 5. **Readarr** - Book Management
- **URL**: https://readarr.woxie.xyz
- **Purpose**: Automate book/audiobook downloads and management
- **Storage**: 2Gi config, 20Gi book library (shared), 100Gi downloads (shared)

### 6. **Bazarr** - Subtitle Management
- **URL**: https://bazarr.woxie.xyz
- **Purpose**: Automated subtitle downloads for movies and TV shows
- **Storage**: 1Gi config, access to movie and TV libraries

### 7. **slskd** - Soulseek Daemon
- **URL**: https://slskd.woxie.xyz
- **Purpose**: P2P file sharing via Soulseek network
- **Storage**: 1Gi config, access to downloads and music folders

### 8. **Jellyfin** - Media Server
- **URL**: https://jellyfin.woxie.xyz
- **Purpose**: Stream movies, TV shows, music, and books
- **Storage**: 10Gi config, 10Gi cache, access to all media libraries
- **Resources**: Up to 4 CPU cores and 4GB RAM for streaming

### 9. **Tdarr** - Media Transcoding
- **URL**: https://tdarr.woxie.xyz
- **Purpose**: Automated media transcoding and optimization
- **Components**: 
  - Tdarr Server (management interface)
  - Tdarr Node (transcoding worker)
- **Storage**: 2Gi config, 50Gi transcode cache, access to all media libraries
- **Resources**: Up to 6 CPU cores and 6GB RAM for transcoding

### 10. **Nextcloud** - Cloud Storage
- **URL**: https://nextcloud.woxie.xyz
- **Purpose**: Personal cloud storage and file sharing
- **Components**:
  - Nextcloud application
  - PostgreSQL database
- **Storage**: 50Gi data volume, 5Gi database volume

## Security Configuration

### Authentication
All services are protected by **Authentik** authentication via Traefik's forward authentication middleware. Users must authenticate through https://auth.woxie.xyz before accessing any media service.

### SSL/TLS
All services use:
- **HTTPS** with Let's Encrypt certificates via cert-manager
- **Wildcard certificate** for *.woxie.xyz domain
- **Cloudflare** DNS challenge for certificate validation

## Storage Architecture

### Shared Volumes
- `media-downloads` (100Gi) - Shared by all *arr apps and slskd
- `media-movies` (100Gi) - Shared by Radarr, Jellyfin, Bazarr, Tdarr
- `media-tv` (100Gi) - Shared by Sonarr, Jellyfin, Bazarr, Tdarr
- `media-music` (50Gi) - Shared by Lidarr, Jellyfin, slskd, Tdarr
- `media-books` (20Gi) - Shared by Readarr, Jellyfin

### Individual Volumes
- Per-service config volumes (1-2Gi each)
- Jellyfin cache (10Gi)
- Tdarr transcode cache (50Gi)
- Nextcloud data and database (55Gi total)

### Total Storage Required
Approximately **500GB+** of persistent storage

## Resource Requirements

### CPU
- **Minimum**: 6 cores
- **Recommended**: 10+ cores
- **Burst**: Up to 14 cores (when transcoding)

### Memory
- **Minimum**: 8GB RAM
- **Recommended**: 12GB+ RAM
- **Burst**: Up to 16GB RAM (when transcoding)

## Deployment

### ArgoCD Configuration
- **Application**: `media-apps`
- **Namespace**: `media-apps`
- **Path**: `infrastructure/media-apps/`
- **Auto-sync**: Enabled with self-heal

### Bootstrap
The media stack is defined in `bootstrap/media-apps.yaml` and will be automatically deployed when the root-app syncs.

## Configuration Files

All configuration files are located in:
```
infrastructure/media-apps/
├── namespace.yaml
├── prowlarr.yaml
├── sonarr.yaml
├── radarr.yaml
├── lidarr.yaml
├── readarr.yaml
├── bazarr.yaml
├── jellyfin.yaml
├── slskd.yaml
├── tdarr.yaml
├── nextcloud.yaml
└── README.md
```

## Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] Configured Cloudflare API token in infrastructure secrets
- [ ] Configured Authentik bootstrap credentials
- [ ] **Updated Nextcloud database passwords** in `infrastructure/media-apps/nextcloud.yaml`
- [ ] Verified cluster has sufficient storage capacity (500GB+)
- [ ] Verified cluster has sufficient compute resources
- [ ] Reviewed and adjusted resource limits if needed
- [ ] Configured Authentik applications for each service

## Post-Deployment Tasks

After deployment:

1. **Configure Authentik** - Set up forward authentication for all media services
2. **Configure Prowlarr** - Add indexers and connect to *arr apps
3. **Configure Download Paths** - Set up proper paths in each *arr app
4. **Configure Jellyfin** - Add media libraries pointing to shared volumes
5. **Configure Bazarr** - Connect to Sonarr and Radarr
6. **Configure Tdarr** - Set up transcoding libraries and rules
7. **Configure Nextcloud** - Complete initial setup wizard

## Monitoring

Check deployment status:
```bash
# Check all pods
kubectl get pods -n media-apps

# Check PVCs
kubectl get pvc -n media-apps

# Check ingress routes
kubectl get ingressroute -n media-apps

# View logs for a specific service
kubectl logs -n media-apps deployment/<service-name> -f
```

## Support

For detailed setup instructions, see:
- [Media Stack README](infrastructure/media-apps/README.md)
- [Authentik Setup Guide](AUTHENTIK-SETUP.md)
- [Main README](README.md)

---

**Status**: ✅ Complete and ready for deployment
**Last Updated**: 2026-02-11
