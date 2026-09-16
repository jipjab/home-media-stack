# Setup Arcane — Docker Management UI

## Overview

Arcane = interface management centralisée pour tous services Docker. Monitor + manage containers, logs, stats, volumes.

**Port :** 8080  
**URL :** http://localhost:8080  
**Internal network :** 172.20.0.30

## Prerequisites

- Docker Compose running (étapes 1-2)
- Autres services peuvent être running ou stopped (Arcane manages all)
- `/var/run/docker.sock` accessible (mounted read-only)

## Start Arcane Container

```bash
docker compose up -d arcane

# Vérifier démarrage
docker logs -f arcane
```

Attendre 20-30s (initialisation).

## First Access

http://localhost:8080

Welcome screen → **Setup** ou direct access si déjà setup.

## Initial Configuration

### 1. Create Admin Account

First login :
- **Username :** (votre prénom)
- **Email :** (votre email)
- **Password :** (fort)
- **Confirm Password**
- **Create Account**

Vous êtes admin Arcane.

### 2. Connect Docker Daemon

Arcane auto-detects Docker via socket (`/var/run/docker.sock` mounted).

**Dashboard** → should see **Docker Status : Connected** (green checkmark)

Si red/error :
- Verify socket mounted : `ls -la /var/run/docker.sock`
- Restart Arcane : `docker restart arcane`

## Dashboard Overview

**Home** tab affiche :
- Docker daemon status
- Running containers count
- Images, volumes, networks stats
- System resources (CPU, memory)

## Containers Management

### View All Containers

**Containers** tab :

List affiche tous containers (running + stopped) :
- plex
- jellyfin
- radarr
- sonarr
- lidarr
- arcane (itself)

Click container → affiche details :
- Status (running/stopped)
- Ports
- Volumes mounted
- Environment vars
- Resource usage (CPU, mem)

### Monitor Container

Click container → **Logs** tab :

Real-time logs (tail) pour troubleshooting.

Example : `docker logs -f plex` = click Plex → Logs → see output live.

### Control Container

**Actions** (button) :
- **Start** (if stopped)
- **Stop** (graceful shutdown)
- **Restart** (restart service)
- **Pause** (pause processes)
- **Remove** (delete container) ⚠️

Use carefully. Most cases : Stop/Restart sufficient.

## Statistics & Monitoring

**Stats** tab (per container) :
- CPU %
- Memory usage (MB)
- Network I/O (bytes sent/received)
- Block I/O (disk read/write)

Useful to detect bottlenecks :
- High CPU → transcode heavy, or indexer searches
- High memory → Plex library large, or cache
- Disk I/O → downloads writing, library scan

## Images Management

**Images** tab :

List all Docker images pulled :
- plexinc/pms-docker
- jellyfin/jellyfin
- linuxserver/radarr
- etc.

Features :
- **Pull** new image (update)
- **Inspect** : see details (layers, env vars)
- **Remove** : delete image (if not in use)

Update containers : Pull latest image → Recreate container → docker-compose down/up.

## Volumes

**Volumes** tab :

List volumes (persistent storage) :
- plex-config
- jellyfin-config
- radarr-config
- sonarr-config
- lidarr-config
- arcane-config

Click → see mount points, size, contents.

Useful for backing up (export volume).

## Networks

**Networks** tab :

List networks (container communication) :
- media-net (custom, created by compose)
- bridge (default Docker)

Verify "media-net" = all arr-services on same network = can communicate.

## Terminal (Optional Advanced)

**Terminal** tab (if enabled) :

Execute commands inside container.

Example : inside Radarr container, check logs :
```bash
cat /config/logs/Radarr.Detailed.log
```

Useful for deep troubleshooting (Phase 2+).

## Accessing Service UIs from Arcane

Arcane = management only. To access service UIs :
- Plex : http://localhost:32400 (separate browser tab)
- Jellyfin : http://localhost:8096 (separate browser tab)
- Radarr : http://localhost:7878 (separate browser tab)
- etc.

Arcane shows status/logs, but doesn't proxy service UI.

## Real-Time Monitoring Example

Scenario : Monitor Radarr while adding film.

1. **Radarr** → Add film (separate browser tab)
2. **Arcane** → Containers → Radarr → **Logs**
3. Watch live logs : Radarr searching indexer, downloading, moving file
4. Check **Stats** tab : see CPU spike during search, I/O during move

Powerful for observability.

## Backup Configurations (Optional Phase 2+)

Arcane can export container configs :

**Volumes** → select plex-config → **Export**

Downloads backup of Plex config (useful if container crash).

Implement systematic backup (Phase 2 runbook).

## Troubleshooting with Arcane

### Container Not Starting

**Containers** tab → click failing container → **Logs**

Error message usually obvious :
- `PLEX_TOKEN invalid` → fix .env
- `Port 32400 already in use` → conflict
- `Permission denied /mnt/media` → mount issue

Fix root cause → **Restart** container → verify logs OK.

### High CPU Usage

**Containers** → Stats tab (sort by CPU)

Identify culprit :
- Plex : likely transcoding (many users streaming)
- Radarr/Sonarr : indexer search (slow indexer or rate limit)
- Jellyfin : transcoding

**Action** :
- Plex : reduce transcode quality
- Radarr/Sonarr : disable slow indexer, increase delay
- Jellyfin : reduce concurrent streams

### Low Disk Space

**Dashboard** → check storage stats

If `/mnt/media` near full :
- Check `/mnt/media/downloads/` (stalled downloads, cleanup)
- Prune old files (delete watched films, old episodes)
- Expand disk (Phase 2)

## API Access (Advanced)

Arcane exposes Docker API (if enabled in settings).

For now : not needed. UI sufficient for MVP.

## Security Notes

### Read-Only Socket

Arcane mounts `/var/run/docker.sock:ro` (read-only).

Prevents accidental deletes via Arcane UI (safer).

For dangerous ops (delete image/container) : require CLI (intentional).

### No Authentication Between Services

Containers on media-net = all trusted (internal LAN).

If external exposure : secure with VPN/firewall Phase 2+.

## API Key (Optional)

Arcane can generate API key for external integrations.

**Settings** (gear) → **API Keys** → **Generate**

For MVP : skip. Nice-to-have Phase 2.

## Next Steps

1. Access http://localhost:8080
2. Verify all 6 services listed (plex, jellyfin, radarr, sonarr, lidarr, arcane)
3. Click each → verify logs OK (no errors)
4. Keep Arcane tab open during Étape 8+ (watch indexer config in real-time)
5. Proceed Étape 8 (Indexers config)

## Why Arcane vs. CLI

| Task | CLI | Arcane |
|------|-----|--------|
| Start/stop container | `docker restart plex` | Click, instant |
| View live logs | `docker logs -f plex` | Logs tab, formatted |
| Monitor CPU/mem | `docker stats` | Real-time graphs |
| Browse volumes | `docker volume inspect` | File explorer UI |
| Emergency debug | Faster (no UI load) | Better for learning |

MVP : Arcane for observability + management.
CLI for automation (scripts) + emergencies.

Both complement (not replace each other).

## Decision Notes

Arcane = modern UI, lightweight, open-source Docker management.

Alternatives : Portainer (heavier), Lazydocker (CLI), Docker Desktop (UI, but resource-heavy).

Arcane chosen : balance simplicity + features + lightweight.

See repo for updates / issues : https://getarcane.app/
