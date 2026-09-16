# Setup Plex Media Server

## Overview

Plex est le serveur média principal, accessible localement et en remote via Plex Remote Access natif (sécurisé).

**Port :** 32400  
**URL :** http://localhost:32400  
**Remote :** Plex app ou web (via compte Plex)

## Prerequisites

- Docker Compose running (étapes 1-2)
- `.env` rempli avec `PLEX_TOKEN` (token de claim)
- Disque secondaire monté à `/home/media-stack` (voir `docs/volumes-storage.md`)

## Token Plex (PLEX_CLAIM)

1. Aller à https://plex.tv/claim
2. Login compte Plex (créer si needed)
3. Copier token affiché (valide 4 minutes)
4. Coller dans `.env` : `PLEX_TOKEN=your_token_here`
5. Garder le token secret (inclut auth)

⚠️ Token expire après 4 min. Relancer process si expiré.

## Start Container

```bash
docker compose up -d plex

# Vérifier qu'il démarre
docker logs -f plex
```

Attendre 30-60s (initialisation base de données Plex).

## First Access

1. Ouvrir http://localhost:32400
2. Vous êtes auto-loggé (claim link appliqué)
3. Welcome screen → **Next**

## Configure Libraries

⚠️ **Note chemins** : Dans l'UI Plex (containerisé), les chemins `/mnt/media/...` sont corrects (vue interne du container). Sur l'hôte VM, le même contenu est à `/home/media-stack/...`.

### 1. Add Libraries

**Settings** (gear icon top-right) → **Libraries** → **Add Library**

**Ajouter Films :**
- Type : Movies
- Name : Films
- Folder : `/mnt/media/films`
- Add → **Save**

**Ajouter Séries :**
- Type : TV Shows
- Name : Séries
- Folder : `/mnt/media/series`
- Add → **Save**

**Ajouter Musique :**
- Type : Music
- Name : Musique
- Folder : `/mnt/media/music`
- Add → **Save**

### 2. Initial Scan

Plex scanne automatiquement les folders. Vérifier dans :

**Settings** → **Libraries** → **Scan automatically when changes detected** ✓

Première scan peut prendre quelques minutes (dépend nombre fichiers).

## Remote Access

### Vérifier Status

**Settings** → **Remote Access**

Chercher : **Fully accessible** (green checkmark)

Si rouge :
1. Vérifier port 32400 ouvert routeur
2. Vérifier IP advertised correct (`PLEX_ADVERTISE_IP` dans .env)
3. Vérifier règles firewall

### Enable UPnP (optionnel, auto port-forward)

**Settings** → **Remote Access** → **Enable server support for UPnP/NAT-PMP**

Si routeur supporte : auto port-forward. Sinon : port forward manuel routeur.

### Test Remote

1. Depuis network externe (mobile hotspot, autre WiFi)
2. Ouvrir https://app.plex.tv
3. Login avec compte Plex
4. Plex devrait lister ton serveur automatiquement
5. Cliquer → devrait streamer

## Profils Utilisateurs (Famille)

### Admin (You)

Déjà setup via token claim. Tu es propriétaire serveur.

### Ajouter Family Members

**Settings** (gear) → **Users** → **Invite User**

- Email family member
- Lien invite généré
- Ils login, profile créé
- Separate watchlist + recommandations

### Parental Controls

**Settings** → **Users** → Select user → **Parental Controls**

Options :
- Content rating restrictions (G, PG, R, etc.)
- PIN protect (children)
- Watch time limits (optionnel via Plex Pass)

## Advanced Settings (Optional V1)

### Transcoding

**Settings** → **Remote** → **Temporary Directory** 

Plex encode video en streaming. Utilisé `/dev/shm` (ramdisk, rapide).

**Automatic Transcode Quality :** Default OK (auto-adapt bandwidth)

### Metadata

**Settings** → **Library** → Per-library → **Advanced**

- Agent (metadata source) : TheTVDB, TheMovieDB, etc.
- Already optimal defaults.

### Backup

Plex database stored dans `/home/media-stack/docker-data/plex/` (chemin hôte).

Backup recommendations :
- Weekly : `cp -r /home/media-stack/docker-data/plex ~/backups/plex-$(date +%Y%m%d)`
- Ou : utiliser Arcane (Étape 14) pour snapshots

## Troubleshooting

### Plex Ne Démarre Pas

```bash
docker logs plex
```

Chercher erreurs (PLEX_TOKEN invalid, etc.)

Redémarrer :
```bash
docker restart plex
```

### Libraries Ne Scannent Pas

1. Vérifier dossiers existent (hôte) : `ls -la /home/media-stack/films`
2. Vérifier permissions (hôte) : `chmod 755 /home/media-stack/films`
3. **Settings** → **Libraries** → **Scan Now** (forcer scan)
4. Check logs : `docker logs plex | grep -i scan`

### Remote Access Red

1. Check routeur port forward : WAN 32400 → LAN VM:32400
2. Check firewall VM : `sudo ufw status`
3. Vérifier `PLEX_ADVERTISE_IP` correct dans .env
4. Restart container : `docker restart plex`

### Streaming Buffering

- Reduce transcoding (Settings → Playback → Automatic Transcode Quality)
- Check network bandwidth
- Check server CPU/RAM (`docker stats plex`)

## Next Steps

1. Add content to `/home/media-stack/films`, `/home/media-stack/series`, `/home/media-stack/music` (hôte)
2. Trigger library scan (Settings → Libraries → Scan Now)
3. Test playback (Movies tab → click film → Play)
4. Invite family via Settings → Users
5. Proceed Étape 4 (Jellyfin setup)

## API Key (For Arr-Stack Integration)

Étape 5+ (Radarr/Sonarr/Lidarr) requiert Plex API key.

**Settings** → **Remote Access** → **Copy Server Access Token** (bottom)

Store dans `.env` : `PLEX_API_KEY=your_token_here` (si needed pour integration)

Ou retrieve après setup via API:
```bash
curl http://localhost:32400/library/sections \
  -H "X-Plex-Token: YOUR_TOKEN"
```
