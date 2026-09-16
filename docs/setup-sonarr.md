# Setup Sonarr — Séries Auto-Download

## Overview

Sonarr automatise téléchargement séries (TV shows). Comme Radarr mais pour épisodes (gère releases par saison/episode).

**Port :** 8989  
**URL :** http://localhost:8989  
**Internal network :** 172.20.0.21

## Prerequisites

- Docker Compose running (étapes 1-2)
- Radarr running (étape 5)
- Plex running (étape 3)
- Disque secondaire monté `/home/media-stack` (voir `docs/volumes-storage.md`)
- Dossier `/home/media-stack/series` créé (hôte)
- Downloads : volume Docker séparé (partagé avec Radarr, temporaire, auto-géré)

⚠️ **Note chemins** : Dans Sonarr (containerisé), `/mnt/media/...` est le chemin interne container. Sur l'hôte VM, le contenu réel est à `/home/media-stack/...`.

## Start Container

```bash
docker compose up -d sonarr

# Vérifier démarrage
docker logs -f sonarr
```

Attendre 30s (initialisation).

## First Access

http://localhost:8989

Welcome screen → **Continue**

## Configure Root Folder (Plex Integration)

**Settings** (gear) → **Media Management** → **Root Folders**

Add Root Folder :
- Path : `/mnt/media/series`
- Click **Add**

Sonarr scannera ce dossier (détecte séries existantes).

**Optional : Anime Folder**

Separate structure pour anime (if desired) :
- Add second root : `/mnt/media/anime`
- Configure anime-specific settings later

## Configure Indexers (Same as Radarr)

**Settings** → **Indexers** → **Add**

**Primary : Usenet**
- Name : NZBgeek
- Type : Usenet
- URL : https://api.nzbgeek.info
- API Key : [your key]
- Enable : ✓
- **Test** → **Save**

**Secondary : Torrent**
- Name : TMDb Torrent
- Type : Torrent
- Enable : ✓
- **Save**

Same indexers as Radarr OK (both apps use separately).

## Download Client Configuration

**Settings** → **Download Clients** → **Add**

**Usenet** :
- Same SABnzbd/NZBGet config as Radarr
- Category : sonarr (separate from radarr, or same)
- **Test** → **Save**

**Torrent** (optional) :
- Same Transmission/qBittorrent
- Category : sonarr

## Quality Profile Configuration

**Settings** → **Profiles** → **Default**

Or customize :

**Add Profile : TV-HD**
- Name : TV-HD (1080p)
- Upgrades : Allow
- Min : 200 MB
- Max : 3000 MB
- Preferred : 1500 MB
- Quality : 1080p preferred
- **Save**

**Anime** (if separate) :
- Name : Anime-720p
- Preferred : 720p (anime often 720p, not 1080p)
- Min : 100 MB, Max : 1500 MB

## Release Profiles (Quality Gates)

**Settings** → **Profiles** → **Release Profiles** → **Add**

**Avoid CAM/SCREENER**
- Must not contain : `CAM`, `SCREENER`, `HDCAM`
- **Save**

**Prefer Proper/Repack** (optional)
- Must contain : `PROPER`, `REPACK` (indicates fixes)
- Makes Sonarr re-grab if better version found

## Import Existing Shows

**Settings** → **Media Management** → **Root Folders**

Root folder `/mnt/media/series` → Sonarr detects existing shows.

Shows already in Plex = recognized.

## Add Series to Sonarr

**Series** tab → **Add New**

Search show name (ex: Breaking Bad) :
- Results show
- Click → select quality profile
- **Monitored : Yes** (auto-download new episodes)
- **Series Type** : Standard (or Anime if applicable)
- **Save**

Sonarr will :
1. Monitor show
2. Track missing episodes
3. Auto-search new releases
4. Download + organize by season
5. Move to `/mnt/media/series/[Show Name]/Season 01/`
6. Plex scans → episodes appear

## Episode Release Timing

**Settings** → **Indexers** → **Delay**

Sonarr waits [X] hours after release before grabbing (avoids low-quality early uploads).

Default (43 min) good. Increase if many false-grabs.

## First Test Add

1. **Series** → **Add New**
2. Search populaire show (ex: The Office, Game of Thrones)
3. Click → select **TV-HD** profile
4. **Monitored : Yes**
5. **Save**

Sonarr should :
- Identify available episodes
- Search if missing episodes exist
- Queue downloads if found
- Move to `/mnt/media/series/[Show]/Season XX/`

Plex rescans → episodes appear.

## Anime Support (Optional)

If anime series :

1. Create separate root : `/mnt/media/anime`
2. Add profile : Anime-720p
3. When adding series : Series Type → Anime
4. Sonarr applies anime-specific naming (episode numbers can differ)

## API Key

**Settings** → **General** → API Key

Copy if needed integration.

## Monitoring

**Activity** tab :
- Current downloads
- Upcoming episode releases

**History** tab :
- All downloads
- Errors

**Wanted** tab :
- Missing episodes (not yet available in indexers)

Sonarr auto-searches wanted episodes regularly.

## Advanced (Optional)

### Rename Pattern

**Settings** → **Media Management** → **Episode Folder Format**

Default : `Season {season:00}`

Result : `/mnt/media/series/Breaking Bad/Season 01/Breaking Bad S01E01.mkv`

Change if custom naming needed.

### Soft Delete

**Settings** → **Media Management** → **Move to Recycle Bin**

Enable : deleted episodes move to recycle (safe).

### Automatic Search Interval

**Settings** → **Indexers** → **Minimum Age**

Default : searches new releases respecting embargo.

Good for series (episodes premiere once, unlike movies).

## Troubleshooting

### No Episodes Found

- Show misspelled (search exact title)
- Show too new (not yet in indexer DB)
- Indexer down (check Settings → Indexers → Test)

**Fix** : Add second indexer, retry manual search.

### Download Queued But Not Starting

- Download client not configured (Settings → Download Clients)
- Disk full (hôte : `df -h /home/media-stack`)
- Download client error (check logs)

**Fix** : Configure download client, free space, restart Sonarr.

### Episode Not Moving to Library

- Check `/mnt/media/downloads/` (still incomplete)
- Check file permissions
- Restart Sonarr : `docker restart sonarr`

### Plex Not Seeing Episodes

- Verify files in `/mnt/media/series/[Show]/Season XX/`
- **Settings** → **Libraries** → Séries → **Scan Now**
- Wait 1-2 min

## Next Steps

1. Add 5-10 shows (mix old + new)
2. Monitor Activity (watch downloads complete)
3. Verify Plex scans + displays episodes
4. Proceed Étape 7 (Lidarr — musique)

## Comparison with Radarr

| Feature | Radarr | Sonarr |
|---------|--------|--------|
| Content | Films | Séries |
| Episode tracking | N/A | Per-episode search + download |
| Release timing | Release day | Episode day (weekly/daily) |
| Rename pattern | Movie folder | Season/Episode structure |

Both use same indexers + download clients (shared).

Parallel operation OK (both can download simultaneously if disk/bandwidth allow).

## Decision Rationale

Sonarr = arr-stack standard for series (mature, 12+ years, large community).

See `docs/decisions/002-arr-stack-choice.md`.
