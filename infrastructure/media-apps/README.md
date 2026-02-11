# Media Stack Infrastructure

This directory contains the complete media automation and management stack for the Skoxie-Argo deployment. All services are configured with Traefik ingress and secured with Authentik authentication.

## 🎬 Included Services

### Media Management (arr-stack)
- **Prowlarr** (prowlarr.woxie.xyz) - Indexer manager for all *arr applications
- **Sonarr** (sonarr.woxie.xyz) - TV show automation and management
- **Radarr** (radarr.woxie.xyz) - Movie automation and management
- **Lidarr** (lidarr.woxie.xyz) - Music automation and management
- **Readarr** (readarr.woxie.xyz) - Book/audiobook automation and management
- **Bazarr** (bazarr.woxie.xyz) - Subtitle management for movies and TV shows

### Media Consumption
- **Jellyfin** (jellyfin.woxie.xyz) - Media server for streaming movies, TV, music, and books
- **slskd** (slskd.woxie.xyz) - Soulseek daemon for peer-to-peer file sharing

### Media Processing
- **Tdarr** (tdarr.woxie.xyz) - Automated transcoding and media library optimization

### Cloud Storage
- **Nextcloud** (nextcloud.woxie.xyz) - Personal cloud storage and collaboration platform

## 📦 Storage Architecture

The stack uses shared persistent volumes for efficient storage:

- `media-downloads` (100Gi) - Shared downloads directory for all *arr apps
- `media-movies` (100Gi) - Movie library shared between Radarr, Jellyfin, Bazarr, and Tdarr
- `media-tv` (100Gi) - TV show library shared between Sonarr, Jellyfin, Bazarr, and Tdarr
- `media-music` (50Gi) - Music library shared between Lidarr, Jellyfin, slskd, and Tdarr
- `media-books` (20Gi) - Book library shared between Readarr and Jellyfin
- Individual config PVCs for each application
- `tdarr-transcode-cache` (50Gi) - Temporary transcoding storage
- `nextcloud-data` (50Gi) - Nextcloud files and apps
- `nextcloud-db` (5Gi) - PostgreSQL database for Nextcloud

### Storage Requirements

**IMPORTANT**: Shared media volumes (media-downloads, media-movies, media-tv, media-music, media-books) use **ReadWriteMany (RWX)** access mode since they are mounted by multiple pods simultaneously. 

Your Kubernetes cluster must have a StorageClass that supports RWX, such as:
- NFS
- CephFS
- GlusterFS
- Cloud provider shared storage (EFS, Azure Files, GCP Filestore)

If your cluster only supports ReadWriteOnce (RWO), pods may fail to schedule. Consider setting up NFS or using a different storage solution.

## 🔐 Security

All services are protected by Authentik authentication via the `pangolin-auth` middleware. Users must authenticate through Authentik at auth.woxie.xyz before accessing any media service.

### Required Authentik Configuration

After deployment, you'll need to configure Authentik:

1. Access Authentik at https://auth.woxie.xyz
2. Create application providers for each service
3. Configure forward authentication for Traefik
4. See [AUTHENTIK-SETUP.md](../../AUTHENTIK-SETUP.md) for detailed instructions

### Nextcloud Secrets

**IMPORTANT**: Before deployment, update the credentials in `nextcloud.yaml`:

```yaml
stringData:
  POSTGRES_PASSWORD: "CHANGEME_SECURE_PASSWORD"
  NEXTCLOUD_ADMIN_USER: "admin"
  NEXTCLOUD_ADMIN_PASSWORD: "CHANGEME_ADMIN_PASSWORD"
```

Generate secure passwords:
```bash
openssl rand -base64 32
```

## 🚀 Deployment

The media stack is automatically deployed via ArgoCD using the App of Apps pattern:

1. The root-app deploys `bootstrap/media-apps.yaml`
2. The media-apps Application syncs all manifests from `infrastructure/media-apps/`
3. ArgoCD handles creation of namespaces, PVCs, deployments, services, and ingress routes

### Manual Deployment

If needed, you can manually deploy:

```bash
kubectl apply -f bootstrap/media-apps.yaml
```

Or sync via ArgoCD:

```bash
argocd app sync media-apps
```

## 🌐 Access URLs

Once deployed and DNS has propagated, access services at:

- https://prowlarr.woxie.xyz - Configure indexers
- https://sonarr.woxie.xyz - Manage TV shows
- https://radarr.woxie.xyz - Manage movies
- https://lidarr.woxie.xyz - Manage music
- https://readarr.woxie.xyz - Manage books
- https://bazarr.woxie.xyz - Manage subtitles
- https://jellyfin.woxie.xyz - Stream media
- https://slskd.woxie.xyz - Soulseek downloads
- https://tdarr.woxie.xyz - Manage transcoding
- https://nextcloud.woxie.xyz - Cloud storage

## ⚙️ Initial Configuration

### 1. Configure Prowlarr First

Prowlarr acts as the central indexer manager:

1. Access Prowlarr at https://prowlarr.woxie.xyz
2. Add your indexers (torrent sites, Usenet providers)
3. Connect to Sonarr, Radarr, Lidarr, and Readarr via Settings → Apps

### 2. Configure Download Locations

In each *arr application, configure paths:

- **Sonarr**: Root folder `/tv`, downloads `/downloads`
- **Radarr**: Root folder `/movies`, downloads `/downloads`
- **Lidarr**: Root folder `/music`, downloads `/downloads`
- **Readarr**: Root folder `/books`, downloads `/downloads`

### 3. Configure slskd

1. Access slskd at https://slskd.woxie.xyz
2. Configure Soulseek credentials
3. Set download directory to `/var/slskd/downloads`
4. Set music share directory to `/var/slskd/music`

### 4. Configure Jellyfin

1. Access Jellyfin at https://jellyfin.woxie.xyz
2. Complete initial setup wizard
3. Add libraries:
   - Movies: `/data/movies`
   - TV Shows: `/data/tv`
   - Music: `/data/music`
   - Books: `/data/books`

### 5. Configure Bazarr

1. Access Bazarr at https://bazarr.woxie.xyz
2. Connect to Sonarr and Radarr
3. Configure subtitle providers
4. TV path: `/tv`, Movies path: `/movies`

### 6. Configure Tdarr

1. Access Tdarr at https://tdarr.woxie.xyz
2. Add libraries to transcode:
   - Movies: `/media/movies`
   - TV: `/media/tv`
   - Music: `/media/music`
3. Configure transcode settings and plugins

### 7. Configure Nextcloud

1. Access Nextcloud at https://nextcloud.woxie.xyz
2. Log in with the admin credentials from the secret
3. Complete setup wizard
4. Install recommended apps

## 🔧 Resource Requirements

Minimum cluster resources needed:

- **CPU**: ~6-10 cores (can burst to ~14 cores)
- **Memory**: ~8-12GB RAM
- **Storage**: ~500GB+ for PVCs

### Per-Service Resources

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|------------|-----------|----------------|--------------|
| Prowlarr | 100m | 500m | 256Mi | 512Mi |
| Sonarr | 100m | 1000m | 256Mi | 1Gi |
| Radarr | 100m | 1000m | 256Mi | 1Gi |
| Lidarr | 100m | 1000m | 256Mi | 1Gi |
| Readarr | 100m | 1000m | 256Mi | 1Gi |
| Bazarr | 100m | 500m | 256Mi | 512Mi |
| Jellyfin | 500m | 4000m | 512Mi | 4Gi |
| slskd | 100m | 1000m | 256Mi | 1Gi |
| Tdarr Server | 500m | 2000m | 512Mi | 2Gi |
| Tdarr Node | 500m | 4000m | 512Mi | 4Gi |
| Nextcloud | 250m | 2000m | 512Mi | 2Gi |
| Nextcloud DB | 100m | 1000m | 256Mi | 1Gi |

## 🐛 Troubleshooting

### Check Application Status

```bash
kubectl get pods -n media-apps
kubectl get pvc -n media-apps
kubectl get ingress -n media-apps
```

### Check Logs

```bash
# View logs for a specific app
kubectl logs -n media-apps deployment/sonarr -f
kubectl logs -n media-apps deployment/jellyfin -f

# View Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f
```

### Common Issues

#### PVC Pending
- Check if your cluster has a default StorageClass
- Ensure sufficient disk space on nodes

#### Can't Access Services
- Verify DNS has propagated: `nslookup prowlarr.woxie.xyz`
- Check Traefik IngressRoutes: `kubectl get ingressroute -n media-apps`
- Check Authentik middleware is configured

#### Jellyfin Can't See Media
- Verify PVCs are mounted correctly
- Check permissions on media directories
- Ensure *arr apps have written media to the correct paths

## 📚 Additional Resources

- [Prowlarr Documentation](https://wiki.servarr.com/prowlarr)
- [Sonarr Documentation](https://wiki.servarr.com/sonarr)
- [Radarr Documentation](https://wiki.servarr.com/radarr)
- [Lidarr Documentation](https://wiki.servarr.com/lidarr)
- [Readarr Documentation](https://wiki.servarr.com/readarr)
- [Bazarr Documentation](https://wiki.bazarr.media/)
- [Jellyfin Documentation](https://jellyfin.org/docs/)
- [slskd Documentation](https://github.com/slskd/slskd)
- [Tdarr Documentation](https://docs.tdarr.io/)
- [Nextcloud Documentation](https://docs.nextcloud.com/)

## 🔄 Updates and Maintenance

All container images use the `latest` tag and will be updated automatically by ArgoCD when new versions are available. For production deployments, consider pinning to specific versions.

## 🎯 Recommended Setup Workflow

1. Deploy the stack via ArgoCD
2. Wait for all pods to be running
3. Configure Authentik authentication
4. Set up Prowlarr with indexers
5. Configure all *arr apps and connect them to Prowlarr
6. Set up download clients in *arr apps
7. Add content to *arr apps
8. Configure Jellyfin with media libraries
9. Set up Bazarr for subtitles
10. Configure Tdarr for transcoding (optional)
11. Set up Nextcloud for cloud storage

---

Built for woxie.xyz | Secured with Authentik | Powered by ArgoCD
