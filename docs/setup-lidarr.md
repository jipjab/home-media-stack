# Setup Lidarr — Musique Auto-Download

## Overview

Lidarr automatise téléchargement musique (albums, tracks). Comme Radarr/Sonarr mais pour audio (gère artists, albums, metadata Musicbrainz).

**Port :** 8686  
**URL :** http://localhost:8686  
**Internal network :** 172.20.0.22

## Prerequisites

- Docker Compose running (étapes 1-2)
- Radarr + Sonarr running (étapes 5-6)
- Plex running (étape 3)
- Disque secondaire monté `/home/media-stack` (voir `docs/volumes-storage.md`)
- Dossier `/home/media-stack/music` créé (hôte)
- Downloads : volume Docker séparé (partagé, temporaire, auto-géré)

⚠️ **Note chemins** : Dans Lidarr (containerisé), `/mnt/media/...` est le chemin interne container. Sur l'hôte VM, le contenu réel est à `/home/media-stack/...`.

## Start Container

```bash
docker compose up -d lidarr

# Vérifier démarrage
docker logs -f lidarr
```

Attendre 30s (initialisation).

## First Access

http://localhost:8686

Welcome screen → **Continue**

## Configure Root Folder

**Settings** (gear) → **Media Management** → **Root Folders**

Add Root Folder :
- Path : `/mnt/media/music`
- Click **Add**

Lidarr scannera ce dossier (détecte artistes/albums existants).

## Configure Indexers (Torrent Primary for Music)

**Settings** → **Indexers** → **Add**

**Primary : Torrent** (Music better on torrent)
- Name : Torrent (ex: TPB if accessible, or generic torrent indexer)
- Type : Torrent
- URL : [torrent indexer URL]
- Enable : ✓
- **Test** → **Save**

**Secondary : Usenet** (optional fallback)
- Name : NZBgeek
- Type : Usenet
- Enable : ✓
- **Save**

⚠️ Music torrent > usenet (better coverage, metadata).

## Download Client Configuration

**Settings** → **Download Clients** → **Add**

**Torrent Client** :
- Type : Transmission or qBittorrent
- Host : localhost
- Port : 6881 (transmission) or 6881 (qBittorrent)
- Username/Password : if auth required
- Category : lidarr
- **Test** → **Save**

**Usenet** (optional) :
- Same SABnzbd/NZBGet as Radarr
- Category : lidarr
- **Save**

## Quality Profile Configuration

**Settings** → **Profiles** → **Default**

Or customize :

**FLAC (Lossless, Recommended)**
- Name : Lossless
- Upgrades : Allow
- Min : 50 MB
- Max : 2000 MB
- Preferred : 300 MB
- Format : FLAC 24-bit (highest quality, large files)
- **Save**

**MP3 (Compressed, Smaller)**
- Name : MP3-320
- Min : 30 MB
- Max : 500 MB
- Preferred : 80 MB
- Format : MP3 320 kbps
- **Save**

**Choice** :
- Musicians/audiophiles : FLAC
- Casual listening : MP3-320
- Both : create both profiles, user choice per album

## Metadata Configuration

**Settings** → **Metadata** → **Musicbrainz**

Lidarr uses Musicbrainz (open music DB) for metadata.

Default settings OK (auto-fetch artist info, album covers).

## Import Existing Music Library

**Settings** → **Media Management** → **Root Folders**

Root `/mnt/media/music` → Lidarr scans, detects artists.

Albums/tracks already in Plex = recognized.

## Add Artists to Lidarr

**Artists** tab → **Add New**

Search artist name (ex: Coldplay) :
- Results show (Musicbrainz matches)
- Click → select quality profile (FLAC or MP3)
- **Monitored : Yes** (auto-download new albums)
- **Albums to monitor** : select which albums (or All)
- **Save**

Lidarr will :
1. Track artist
2. Monitor new releases
3. Search torrent indexer
4. Download albums
5. Organize : `/mnt/media/music/[Artist Name]/[Album Name]/01 - Track Name.flac`
6. Plex scans → albums + tracks appear

## First Test Add

1. **Artists** → **Add New**
2. Search populaire artiste (ex: The Beatles, Adele)
3. Click → select **FLAC** or **MP3-320** profile
4. **Monitored : Yes**
5. Select albums (or All)
6. **Save**

Lidarr should :
- Identify available albums
- Search torrent indexer
- Queue downloads
- Organize to `/mnt/media/music/[Artist]/[Album]/`

Plex rescans → music library populated.

## Naming Convention

**Settings** → **Media Management** → **Artist Folder Format**

Default : `{Artist Name}`

**Album Folder Format** : `{Album Title} [{Release Date}]`

**Track Format** : `{Track Number:00} - {Track Title}`

Result :
```
/mnt/media/music/
├── The Beatles/
│   ├── Abbey Road [1969]/
│   │   ├── 01 - Come Together.flac
│   │   ├── 02 - Something.flac
│   │   └── ...
│   └── The White Album [1968]/
│       └── ...
└── Pink Floyd/
    └── The Wall [1979]/
        └── ...
```

Plex reads this structure natively.

## API Key

**Settings** → **General** → API Key

Copy if needed (low priority for MVP).

## Monitoring

**Activity** tab :
- Current album downloads
- Queue status

**History** tab :
- All downloads (success/fail)
- Timestamps

**Wanted** tab :
- Missing albums (not yet available)

Lidarr re-searches weekly.

## Advanced (Optional)

### Multiple Artists Same Name

Lidarr uses Musicbrainz ID (MBID) to disambiguate (ex: multiple "John Smith" artists).

Usually auto-resolved. If conflict : use MBID search.

### Rejected Releases

If Lidarr rejects a download :
- Check release format (must match quality profile)
- Check size constraints
- Release may be marked fake/fake-FLAC

**Fix** : Manually accept in Activity if legitimate, or add to approved in Release Profile.

### Stalled Downloads

If torrent stuck :

1. Check download client (Transmission/qBittorrent UI)
2. Check seeders (if 0 seeds, dead torrent)
3. Restart torrent client : `docker restart transmission` (or qbittorrent)

## Troubleshooting

### Artist Not Found

- Misspelled (search exact name)
- Obscure/new artist (may not be in Musicbrainz yet)
- Try MBID search (advanced)

### No Albums Found

- Indexer down (Settings → Indexers → Test)
- Album too new/rare (not available torrent)
- Metadata mismatch (Lidarr sees different MBID)

**Fix** : Add second indexer, search manually torrent site, add to library later.

### Download Incomplete

- Torrent: not enough seeders (wait or retry)
- File: incomplete in `/mnt/media/downloads/`

**Fix** : Force retry in Activity, or remove + re-add album.

### Plex Not Seeing Music

- Verify files : `ls /mnt/media/music/`
- Check format : must be `.flac`, `.mp3`, etc.
- **Settings** → **Libraries** → Musique → **Scan Now**
- Wait 1-2 min

## Lidarr vs Radarr/Sonarr

| Feature | Radarr | Sonarr | Lidarr |
|---------|--------|--------|--------|
| Content | Films | Séries | Musique |
| Metadata | TheMovieDB | TheTVDB | Musicbrainz |
| Organization | Folder/File | Season/Episode | Artist/Album/Track |
| Recommended Indexer | Usenet primary | Usenet primary | Torrent primary |

Lidarr younger than Radarr/Sonarr (less mature community) but solid for music.

## Next Steps

1. Add 5-10 artists
2. Mix: populaire (coverage good) + niche (test fallback)
3. Monitor downloads complete
4. Verify Plex music library populated
5. Proceed Étape 8 (Indexers config consolidation + hybrid setup)

## Music Quality Note

FLAC = lossless (original studio quality, larger files ~300-500 MB/album)

MP3-320 = lossy (human ear can't usually tell, smaller ~50-100 MB/album)

Choose based on:
- Audiophile gear → FLAC
- Casual listening → MP3-320
- Storage space limited → MP3-320
- Future-proof → FLAC (lossless archival)

## Decision Rationale

Lidarr = arr-stack music component (mature, Musicbrainz integration solid).

See `docs/decisions/002-arr-stack-choice.md`.

Torrent primary for music = better coverage (niche albums rare on usenet).

See `docs/decisions/003-indexer-strategy-hybrid.md`.
