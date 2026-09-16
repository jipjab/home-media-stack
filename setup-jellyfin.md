# Setup Jellyfin Media Server

## Overview

Jellyfin est open-source media server, parallèle à Plex. Même contenu (disque local `/home/media-stack`), UI/profils séparés.

**Ports :** 8096 (HTTP), 8920 (HTTPS)  
**URL :** http://localhost:8096 ou https://localhost:8920  
**Certificat :** Auto-signé (browser warning normal)

## Prerequisites

- Docker Compose running (étapes 1-2)
- Disque secondaire monté à `/home/media-stack` (voir `docs/volumes-storage.md`)
- Script certificat auto-signé exécutable

## Generate Self-Signed Certificate

Jellyfin HTTPS requiert certificat. Générer auto-signé au démarrage :

```bash
bash scripts/gen-jellyfin-cert.sh
```

Cela crée (chemin hôte) :
- `/home/media-stack/docker-data/jellyfin/cert.crt`
- `/home/media-stack/docker-data/jellyfin/key.key`

Valide 1 an. Renew annuel via même script (overwrite).

## Start Container

```bash
docker compose up -d jellyfin

# Vérifier démarrage
docker logs -f jellyfin
```

Attendre 30-60s (initialisation).

## First Access

### HTTP (Simplifié)

http://localhost:8096

Welcome screen → **Let's go!**

### HTTPS (Recommandé)

https://localhost:8920

⚠️ Browser warning normal (certificat auto-signé).

**Action :** Click **Advanced** → **Proceed** (ou **Accept Risk** selon browser)

## Configure Administration

### Create Admin Account

Welcome screen :
1. **Username :** (votre prénom)
2. **Password :** (fort, noter!)
3. **Next**

Compte créé = admin Jellyfin.

### Configure Server Name

**Settings** (gear icon) → **General** → **Server Name**

Example : `Home Media Server`

## Configure Libraries

⚠️ **Note chemins** : Dans l'UI Jellyfin (containerisé), `/mnt/media/...` est correct (vue interne container). Sur l'hôte VM, même contenu à `/home/media-stack/...`.

### Add Libraries (Parallèle Plex)

**Settings** → **Libraries** → **Add Media Library**

**Films :**
- Name : Films
- Type : Movies
- Folder : `/mnt/media/films`
- Add

**Séries :**
- Name : Séries
- Type : Shows
- Folder : `/mnt/media/series`
- Add

**Musique :**
- Name : Musique
- Type : Music
- Folder : `/mnt/media/music`
- Add

### Media Scan

Jellyfin scanne auto. Verify :

**Settings** → **Libraries** → Monitor chaque library

Première scan ~5-10 min.

Forcer scan :
```bash
docker exec jellyfin curl -X POST \
  http://localhost:8096/api/Library/Refresh \
  -H "X-MediaBrowser-Token: YOUR_API_KEY"
```

(API key via Settings après première login)

## Networking Setup

### Local Access

http://localhost:8096 = accessible depuis VM, network LAN.

### HTTPS Local Network

https://localhost:8920 sur LAN.

Browser warning : normal (auto-signé, chiffré quand même).

Accepter une fois → saved (browser cache).

### Remote Access (Optional V2)

Jellyfin supporte remote mais recommandé Phase 2+.

Pour maintenant : local LAN uniquement.

## User Profiles (Famille)

### Create Family Profiles

**Settings** (admin gear) → **Users** → **Add User**

**Options :**

- **Name :** Member prénom
- **Password :** (can be short PIN for children)
- **Enable user :** ✓
- **Administrator :** ☐ (unchecked pour enfants)

Add → sauvegardé

### Parental Controls (Optional)

**Settings** → **Users** → Select User → **Edit**

**Content Ratings :**
- Dropdown : G, PG, R, etc.
- Restrict content above rating

Example : Child = G only (restricts PG+)

### Library Visibility

**Settings** → **Users** → Select User

**Media Libraries :** Check/uncheck qui peut voir

Example : enfants voient Films + Séries, pas admin content

## Test Setup

### Local Playback

1. **Home** tab
2. **Films** → select film
3. **Play**
4. Vérifier audio/video ok

### HTTPS Certificate Warning

1. https://localhost:8920
2. Browser popup : "Certificate not trusted"
3. **Advanced** → **Proceed anyway**
4. Should load HTTPS ✓

Browser remembers → pas rewarning next time.

### Family Login

1. Logout (top-right → Logout)
2. Select user (child name)
3. Enter PIN / password
4. Navigate → only visible libraries shown
5. Play film → restricted content hidden ✓

## Network Binding (Optional)

Par défaut : bind 0.0.0.0 (all interfaces).

Si besoin restrict :
**Settings** → **General** → **Networking** (expand)

- **Published Server URL :** leave empty (auto-detect)
- **Known Proxies :** (if reverse proxy ultérieur)

## API Key (For Integration)

Étape 5+ auto-download peut intégrer Jellyfin notification.

**Settings** → **API Keys** → **New API Key**

- Name : Radarr (example)
- Generate

Copy token → store (if needed integration)

For now : optional, non-critical.

## Advanced (Optional Phase 2+)

### Playback Settings

**Settings** → **Playback**

- **Enable Subtitles :** ✓
- **Transcoding :** Auto (default good)
- **Quality :** Adaptive (auto bandwidth)

### Metadata

**Settings** → **Metadata**

Agents (TV, Movies, Music) : defaults optimal.

Change only if metadata mismatch (rare).

### Database Backup

Jellyfin DB stored (chemin hôte) : `/home/media-stack/docker-data/jellyfin/`

Backup like Plex :
```bash
cp -r /home/media-stack/docker-data/jellyfin ~/backups/jellyfin-$(date +%Y%m%d)
```

## Troubleshooting

### HTTPS Certificate Error

```bash
bash scripts/gen-jellyfin-cert.sh
docker restart jellyfin
```

Retry https://localhost:8920

### Libraries Not Scanning

1. Check folders (hôte) : `ls /home/media-stack/films`
2. Force rescan : Settings → Libraries → click library → Refresh

### User Can't Login

1. Verify user exists : Settings → Users
2. Verify password correct
3. Verify "Enable user" ✓
4. Try logout/login again

### Slow Playback

- Check network bandwidth
- Check server CPU : `docker stats jellyfin`
- Reduce transcoding quality : Settings → Playback
- Check file format (MKV = native, no transcode; MP4 same)

## Next Steps

1. Add content (films/séries/musique) to `/home/media-stack/[films|series|music]` (hôte)
2. Verify both Plex + Jellyfin scan correctly
3. Test playback both servers
4. Créer profiles famille (Plex + Jellyfin)
5. Proceed Étape 5+ (auto-download)

## Decision Notes

Jellyfin = open-source, no account required, full control.

Plex + Jellyfin coexist (dual-stack). Choisir UI par preference utilisateur. Métadonnées indépendantes = OK (chacun scanne solo).

See `docs/decisions/001-dual-stack-plex-jellyfin.md` for rationale.
