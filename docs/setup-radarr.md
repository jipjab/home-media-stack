# Setup Radarr — Films Auto-Download

## Overview

Radarr automatise téléchargement films. Cherche indexers, trouve releases, télécharge, organise, intègre Plex.

**Port :** 7878  
**URL :** http://localhost:7878  
**Internal network :** 172.20.0.20

## Prerequisites

- Docker Compose running (étapes 1-2)
- Plex running (étape 3)
- Disque secondaire monté `/home/media-stack` (voir `docs/volumes-storage.md`)
- Dossier `/home/media-stack/films` créé (hôte)
- Downloads : volume Docker séparé (temporaire, auto-géré, pas de dossier hôte à créer)

⚠️ **Note chemins** : Dans Radarr (containerisé), `/mnt/media/...` est le chemin interne container. Sur l'hôte VM, le contenu réel est à `/home/media-stack/...`.

## Start Container

```bash
docker compose up -d radarr

# Vérifier démarrage
docker logs -f radarr
```

Attendre 30s (initialisation).

## First Access

http://localhost:7878

Welcome screen → **Continue**

## Configure Root Folder (Plex Integration)

**Settings** (gear) → **Media Management** → **Root Folders**

Add Root Folder :
- Path : `/mnt/media/films`
- Click **Add**

Radarr scannera ce dossier automatiquement (détecte films existants).

## Configure Indexers (Sources)

### Add Primary Indexer

**Settings** → **Indexers** → **Add**

**Choice 1 : Usenet (Hybrid Primary)**

- Name : NZBgeek (or Nzbndx)
- Type : Usenet
- URL : https://api.nzbgeek.info (example)
- API Key : [your usenet API key]
- Enable : ✓
- Click **Test** → should pass
- **Save**

**Choice 2 : Torrent (Generic)**

- Name : TMDb Torrent
- Type : Torrent
- URL : [Torrent indexer URL, if public]
- Enable : ✓
- **Save**

### Add Secondary Indexer (Fallback)

If hybrid : add torrent after usenet.

Radarr tries usenet first → if miss, fallback torrent auto.

## Download Client Configuration

**Settings** → **Download Clients** → **Add**

**Usenet Downloader (if using usenet):**
- Type : SABnzbd or NZBGet
- Name : SABnzbd
- Host : localhost (or IP if separate)
- Port : 8080 (default SAB)
- API Key : [from SAB settings]
- Category : radarr (optional)
- **Test** → **Save**

**Torrent Downloader (optional, for fallback):**
- Type : Transmission or qBittorrent
- Host : localhost
- Port : 6881 (transmission default) or 6881 (qBittorrent)
- Username/Password : if needed
- **Test** → **Save**

⚠️ For MVP : usenet + generic torrent OK. Torrent client integration Phase 2+.

## Quality Profile Configuration

**Settings** → **Profiles** → Click **Default**

Or create custom :

**Add Quality Profile**
- Name : HD (1080p)
- Upgrades : Allow
- Minimum size : 500 MB
- Maximum size : 5000 MB
- Preferred size : 2500 MB
- Qualities : select 1080p as preferred
- **Save**

**OR for 4K** (optional) :
- Name : 4K
- Preferred : 2160p
- Min/Max : 1000-10000 MB

## Release Profiles (Quality Gates)

**Settings** → **Profiles** → **Release Profiles** → **Add**

**Example : Avoid Bad Releases**
- Must contain : (optional, seeds for torrent)
- Must not contain : `CAM`, `SCREENER`, `HDCAM` (low quality)
- **Save**

This filters out bad quality auto-releases.

## Plex Integration

### Import Existing Library

**Settings** → **Media Management** → **Root Folders**

Root folder `/mnt/media/films` → Radarr scans, detects existing films.

Films you already have in Plex = recognized by Radarr.

### Add Films to Radarr

**Movies** tab → **Add New**

Search film name :
- Results show
- Click film → select quality profile (HD or 4K)
- **Add as Monitored** (enable auto-download)
- **Save**

Radarr will:
1. Search indexers
2. Find best match per profile
3. Download when available
4. Move to `/mnt/media/films/`
5. Plex scans → appears in library

## First Test Download

1. **Movies** → **Add New**
2. Search populaire film (ex: Dune, Oppenheimer)
3. Click → select **HD 1080p** profile
4. **Add as Monitored**
5. Check **Activity** tab

Radarr should :
- Search indexers (1-2 min)
- Propose release candidate
- Download (if torrent/usenet active)
- Move file to `/mnt/media/films/[Film Name]/`

Plex rescans → film appears.

## API Key (For Integration)

**Settings** → **General** → API Key (bottom)

Copy → store (if needed integration Plex/Jellyfin later).

For now : not critical.

## Monitoring & Logs

**Activity** tab :
- Recent downloads
- Errors
- Queue status

**History** tab :
- All downloads (success/fail)
- Timestamps

If download fails :
- Check indexer active (Settings → Indexers)
- Check disk space (hôte : `df -h /home/media-stack`)
- Check download client connected (Settings → Download Clients → Test)

## Advanced Settings (Optional V2)

### Automatic Search Interval

**Settings** → **Indexers** → **Minimum Age** (days before search)

Default OK (Radarr searches new releases, respects embargo period).

### Rename Pattern

**Settings** → **Media Management** → **Movie Folder Format**

Default : `{Movie Title} ({Release Year})`

Result : `/mnt/media/films/Dune (2021)/Dune.2021.mkv`

Change if custom naming needed.

### Soft Delete

**Settings** → **Media Management** → **Move to Recycle Bin**

Enable : deleted films move to `/mnt/media/films/.recycle/` (not permanent).

Disable : permanent delete (risky).

Recommend : enable.

## Troubleshooting

### No Download Candidates Found

- Indexer misconfigured (Settings → Indexers → Test each)
- Film too old/obscure (niche films less available)
- Usenet/torrent service down (check status)

**Fix** : Add second indexer, or wait (Radarr retries daily).

### Download Failed

Check :
1. **Activity** tab → error message
2. **Settings** → **Download Clients** → Test each
3. Disk space (hôte) : `df -h /home/media-stack`
4. File permissions (hôte) : `ls -la /home/media-stack/films`

### File Not Moved to Library

- Check `/mnt/media/downloads/` (incomplete)
- Check file permissions (Radarr can't move)
- Restart Radarr : `docker restart radarr`

### Plex Not Seeing Film

- Verify file in `/mnt/media/films/`
- **Settings** → **Libraries** → Films → **Scan Now** (force)
- Wait 1-2 min (Plex processes)

## Next Steps

1. Test add 3-5 films manually
2. Wait for downloads complete
3. Verify Plex scans + displays
4. Proceed Étape 6 (Sonarr — séries)

## Decision Rationale

Radarr = mature, widely deployed, Plex native integration.

See `docs/decisions/002-arr-stack-choice.md` for rationale.

Indexer strategy (usenet primary + torrent fallback) =

See `docs/decisions/003-indexer-strategy-hybrid.md`.
