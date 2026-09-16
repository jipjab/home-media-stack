# Docker Volumes & Storage Strategy

## Overview

Separation stratégique entre :
- **Docker configs** → SSD local rapide (performance)
- **Media (films, séries, musique)** → SSD local (espace + perf)
- **Downloads (temporary)** → Docker volume (auto-cleanup)

## Storage Layout

```
/home/media-stack/                    (SSD secondaire, 1000G)
├── docker-data/                      (Configs Docker, ~5-10 GB total)
│   ├── plex/                         (~2-3 GB)
│   ├── jellyfin/                     (~1-2 GB)
│   ├── radarr/                       (~500 MB)
│   ├── sonarr/                       (~500 MB)
│   ├── lidarr/                       (~500 MB)
│   └── arcane/                       (~100 MB)
├── films/                            (Contenu films)
├── series/                           (Contenu séries)
└── music/                            (Contenu musique)

Docker volume (local, SSD root)
└── downloads/                        (Temporaire, auto-cleanup)
```

## Docker Volumes Configuration

### Named Volumes (Bind Mounts)

```yaml
volumes:
  plex-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/media-stack/docker-data/plex
```

**What it does** :
- Mounts `/home/media-stack/docker-data/plex` comme volume Docker
- Persistent (survit restart container/daemon)
- Rapide (local SSD, pas de reseau)

### Downloads Volume

```yaml
volumes:
  downloads:
    driver: local
```

**What it does** :
- Docker volume anonyme (stocké dans `/var/lib/docker/volumes/`)
- Temporaire (files deleted after move to films/series/music)
- Rapide (local SSD)

## Service Mounts

### Plex

```yaml
volumes:
  - plex-config:/config                    # Config Docker
  - /home/media-stack/films:/mnt/media/films
  - /home/media-stack/series:/mnt/media/series
  - /home/media-stack/music:/mnt/media/music
  - /dev/shm:/transcode                   # RAM disk transcode
```

- Reads configs de `/home/media-stack/docker-data/plex`
- Accède medias depuis `/home/media-stack/[films|series|music]`
- Transcode en RAM (`/dev/shm`, rapide)

### Radarr

```yaml
volumes:
  - radarr-config:/config               # Config Docker
  - /home/media-stack/films:/mnt/media/films
  - downloads:/mnt/media/downloads      # Temporary
```

- Reads configs de `/home/media-stack/docker-data/radarr`
- Root folder pour films : `/mnt/media/films` (= `/home/media-stack/films`)
- Downloads temporaires : Docker volume `downloads`
- Post-download : move file vers `/mnt/media/films/[Film]/`

### Sonarr

```yaml
volumes:
  - sonarr-config:/config
  - /home/media-stack/series:/mnt/media/series
  - downloads:/mnt/media/downloads
```

Même pattern que Radarr, pour séries.

### Lidarr

```yaml
volumes:
  - lidarr-config:/config
  - /home/media-stack/music:/mnt/media/music
  - downloads:/mnt/media/downloads
```

Même pattern, pour musique.

## Download Workflow

1. **Radarr searches**, finds release
2. **Downloader** (torrent/usenet client) télécharge dans `downloads/` volume
3. **File downloads** complète (ex: `Dune.2021.mkv`)
4. **Radarr post-processing** :
   - Rename file (per profile)
   - Move to `/mnt/media/films/Dune (2021)/Dune.2021.mkv`
   - Update Plex metadata
5. **Downloads volume** auto-cleared (no remnants)

## Storage Expansion

### If /home/media-stack full

**Option 1 : Add secondary disk**
- Partition second drive (ex: `/dev/sdc`)
- Mount at `/home/media-stack-2`
- Update docker-compose volumes for new paths
- Restart services

**Option 2 : Expand current disk**
- Logical volume expand (if using LVM)
- Or replace disk (backup first)

### Backup Strategy (Phase 2+)

Sync films/series/musique vers Synology prévu via **Syncthing** (setup différé, à traiter séparément — voir décision à venir).

En attendant, backup manuel possible :
```bash
# Backup docker-data (configs) vers Synology, exemple rsync ponctuel
rsync -av /home/media-stack/docker-data/ synology:/volume1/backups/docker-data/
```

Configs (Plex/Jellyfin/arr-stack) = critiques, pas couvertes par Syncthing (qui ne synchronise que films/series/musique). Backup manuel recommandé en attendant stratégie définitive.

## Permissions & Ownership

All directories owned by user running Docker :

```bash
ls -la /home/media-stack/

# Should show:
# drwxr-xr-x  user  user  docker-data/
# drwxr-xr-x  user  user  films/
# drwxr-xr-x  user  user  series/
# drwxr-xr-x  user  user  music/
```

Docker containers run as 1000:1000 (PUID/PGID) → matches permissions.

If permission denied :
```bash
sudo chown -R 1000:1000 /home/media-stack/
chmod 755 /home/media-stack/*
```

## Monitoring Disk Usage

Check space used :

```bash
df -h /home/media-stack

# Example output:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sdb1      1000G  250G  750G  25%  /home/media-stack
```

Monitor from Arcane UI :
- **Dashboard** → Storage stats
- Real-time disk usage per container

Alert thresholds :
- 80% used → clean old files / add disk
- 90% used → critical, downloads fail

## Volume Cleanup

Downloads volume should auto-clear after post-processing.

If stuck downloads accumulate :

```bash
# List Docker volumes
docker volume ls | grep downloads

# Inspect volume
docker volume inspect downloads

# Manual cleanup (if needed)
docker volume rm downloads

# Recreate
docker volume create downloads
docker compose up -d
```

⚠️ **Only do if no active downloads.**

## Performance Tuning

### RAM Disk Transcode

Plex uses `/dev/shm` (RAM disk) for transcode.

- Fast (no disk I/O)
- Limited by available RAM
- Auto-cleanup after transcode

If low on RAM : remove `/dev/shm` mount from compose (use disk instead, slower).

### Concurrency Limits

Radarr/Sonarr auto-download :
- Limit to 1-2 concurrent downloads (disk I/O bottleneck)
- Settings → Download Clients → limit concurrency

Docker CPU/memory limits (Phase 2+) :
```yaml
resources:
  limits:
    cpus: '1.5'
    memory: 2G
```

## Troubleshooting

### Container Can't Write to Volume

```bash
# Check permissions
ls -la /home/media-stack/docker-data/radarr/

# Fix if needed
sudo chown 1000:1000 /home/media-stack/docker-data/radarr/
chmod 755 /home/media-stack/docker-data/radarr/

# Restart container
docker restart radarr
```

### Downloads Not Deleting

Check post-processing logs :

```bash
docker logs radarr | grep "post-processing\|error"
```

If stuck :
1. Manual cleanup : `docker exec radarr rm -rf /mnt/media/downloads/*`
2. Restart service : `docker restart radarr`

### Disk Full, Can't Download

1. **Check what's using space** :
   ```bash
   du -sh /home/media-stack/* | sort -h
   ```

2. **Options** :
   - Delete old films/music
   - Cleanup `/var/lib/docker/volumes/downloads/_data/` manually
   - Add disk

3. **Permanent fix** : monitor proactively (cron script + alerts)

## Next Steps

1. Run `scripts/setup-directories.sh` (create structure)
2. Copy `.env.example` → `.env` (fill values)
3. `docker compose up -d` (start all services)
4. Verify volumes mounted : `docker volume ls`
5. Check disk usage : `df -h /home/media-stack`

## Notes

This design prioritizes :
- **Performance** : SSD local configs + media
- **Reliability** : Persistent volumes, no data loss
- **Simplicity** : Bind mounts (readable on host)
- **Scalability** : Easy to expand or backup
