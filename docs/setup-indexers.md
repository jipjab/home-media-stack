# Setup Indexers — Torrent (MVP) + Usenet (Futur)

## Overview

**Décision MVP** : Torrent-only (pas d'abonnement usenet actuellement).

Architecture reste compatible hybrid (usenet + torrent) — ajouter usenet plus tard ne nécessite aucun changement structurel, juste ajouter indexer + downloader dans Radarr/Sonarr/Lidarr.

Voir `docs/decisions/003-indexer-strategy-hybrid.md` — décision originale hybrid, adaptée ici : **Phase MVP = torrent-only**, usenet = ajout futur optionnel (Phase 2+).

## Prerequisites

- Radarr, Sonarr, Lidarr running (étapes 5-7)
- qBittorrent running (ce document)

## Start qBittorrent

```bash
cd /home/media-stack/home-media-stack
docker compose up -d qbittorrent

# Vérifier démarrage
docker logs -f qbittorrent
```

## First Access — Get Default Password

qBittorrent génère password temporaire au premier démarrage.

```bash
docker logs qbittorrent 2>&1 | grep -i "temporary password"
```

Exemple output :
```
The WebUI administrator username is: admin
The WebUI administrator password was not set. A temporary password is provided for this session: aB3dEfG9
```

Note ce mot de passe (change après premier login).

## Access WebUI

http://localhost:8081

- Username : `admin`
- Password : (temporaire, depuis logs)

**Immédiatement après login** :

**Tools** → **Options** → **Web UI** → **Authentication**
- Change password : mot de passe fort permanent
- **Save**

## Configure Download Path

**Tools** → **Options** → **Downloads**

- **Default Save Path** : `/mnt/media/downloads` (déjà mappé au volume Docker)
- **Keep incomplete torrents in** : ✓ (optionnel, sépare incomplets)

## Configure Connection

**Tools** → **Options** → **Connection**

- **Port used for incoming connections** : 6881 (déjà exposé dans compose)
- **Enable UPnP** : optionnel (auto port-forward si routeur supporte)

## Configure Categories (Organisation)

**Tools** → **Options** → **Downloads** → **Categories**

Ou directement dans WebUI (bas de page, clic droit → Add category) :

- `radarr` → save path : `/mnt/media/downloads/radarr`
- `sonarr` → save path : `/mnt/media/downloads/sonarr`
- `lidarr` → save path : `/mnt/media/downloads/lidarr`

Aide Radarr/Sonarr/Lidarr à identifier leurs téléchargements respectifs.

## Get API Key (Not Required for qBittorrent)

qBittorrent n'utilise pas API key classique — Radarr/Sonarr/Lidarr se connectent via username/password WebUI directement.

## Connect qBittorrent to Radarr

**Radarr** → http://localhost:7878

**Settings** → **Download Clients** → **Add** → **qBittorrent**

- **Name** : qBittorrent
- **Host** : `qbittorrent` (nom service Docker, résolution interne réseau `media-net`)
- **Port** : 8080 (port interne container, pas 8081 — 8081 est le port hôte exposé)
- **Username** : admin
- **Password** : (celui changé plus haut)
- **Category** : radarr
- **Test** → doit passer ✓
- **Save**

## Connect qBittorrent to Sonarr

**Sonarr** → http://localhost:8989

**Settings** → **Download Clients** → **Add** → **qBittorrent**

Mêmes paramètres, **Category** : sonarr

**Test** → **Save**

## Connect qBittorrent to Lidarr

**Lidarr** → http://localhost:8686

**Settings** → **Download Clients** → **Add** → **qBittorrent**

Mêmes paramètres, **Category** : lidarr

**Test** → **Save**

## Configure Torrent Indexer (Each App)

Répéter pour **Radarr**, **Sonarr**, **Lidarr** :

**Settings** → **Indexers** → **Add** → choisir type indexer

### Option A — Indexer Public (Rapide, Qualité Variable)

Exemples : 1337x, ThePirateBay (via proxy), YTS (films uniquement)

⚠️ Qualité/fiabilité variable, pas de garantie disponibilité.

### Option B — Indexer Privé (Recommandé, Meilleure Qualité)

Nécessite compte + invitation (ex: trackers privés spécialisés films/séries/musique).

- **Name** : (nom indexer)
- **URL** : (URL indexer)
- **API Key** : (si applicable)
- **Categories** : Movies (Radarr) / TV (Sonarr) / Music (Lidarr)
- **Test** → **Save**

### Option C — Prowlarr (Recommandé, Centralise Tous Indexers)

Au lieu de configurer indexer séparément dans chaque app, **Prowlarr** centralise :
- 1 config indexer → propage auto vers Radarr/Sonarr/Lidarr
- Simplifie maintenance (ajout/suppression indexer en 1 endroit)

**Non inclus MVP** (ajout Phase 2 si complexité indexers augmente). Pour MVP : config directe par app suffit (3 apps × 1-2 indexers = gérable).

## Quality Gates (Filter Bad Releases)

**Settings** → **Indexers** → **Release Profiles** → **Add** (répéter chaque app)

**Must Not Contain** :
```
CAM
SCREENER
HDCAM
TS
```

**Save**

Filtre releases basse qualité automatiquement.

## Test Download

### Radarr Test

1. **Movies** → **Add New**
2. Rechercher film populaire (ex: Interstellar)
3. Sélectionner qualité HD
4. **Add as Monitored**
5. **Activity** tab → vérifier recherche + download démarre

### Vérifier dans qBittorrent

http://localhost:8081

**Transfers** tab → voir torrent en cours (nom, progress %, vitesse)

### Vérifier Completion

Une fois téléchargement 100% :
- Radarr déplace fichier vers `/mnt/media/films/[Film]/`
- qBittorrent conserve seed (optionnel, contribue communauté)
- Plex/Jellyfin scan détecte nouveau fichier

## Seeding Etiquette (Optionnel)

Torrents = pair-à-pair, seed (partage après download) aide écosystème.

**Tools** → **Options** → **BitTorrent** → **Seeding Limits**

- **Ratio limit** : 2.0 (exemple, partage 2x taille téléchargée)
- **Seeding time limit** : 7 days (exemple)

Après limite : auto-stop seed (libère bande passante).

## Ajout Usenet (Futur, Phase 2+)

Quand abonnement usenet acquis (ex: NZBgeek) :

### 1. Choisir Downloader Usenet

- **SABnzbd** ou **NZBGet** (tous deux solides, SABnzbd = UI plus riche)

### 2. Ajouter Service Docker

```yaml
sabnzbd:
  image: linuxserver/sabnzbd:latest
  container_name: sabnzbd
  networks:
    media-net:
      ipv4_address: 172.20.0.26
  ports:
    - "8082:8080/tcp"
  environment:
    PUID: ${RADARR_UID}
    PGID: ${RADARR_GID}
    TZ: ${TZ}
  volumes:
    - sabnzbd-config:/config
    - downloads:/mnt/media/downloads
  restart: unless-stopped
```

### 3. Connecter à Radarr/Sonarr/Lidarr

Même processus que qBittorrent (Settings → Download Clients → Add → SABnzbd).

### 4. Ajouter Indexer Usenet

Settings → Indexers → Add → Usenet (NZBgeek, etc.)

### 5. Priorité (Hybrid)

Radarr/Sonarr/Lidarr essaient indexers par ordre de priorité configuré. Mettre usenet priorité plus haute (recherche plus rapide/fiable) → torrent devient fallback automatique.

**Aucun changement structure existante requis** — ajout pur, coexist avec torrent.

## Monitoring

### qBittorrent Stats

**Transfers** tab :
- Download/upload speed
- Active torrents
- Seeding torrents

### Arcane

**Containers** → qbittorrent → **Stats**

CPU/Memory/Network usage temps-réel.

## Troubleshooting

### qBittorrent WebUI Inaccessible

```bash
docker logs qbittorrent
docker restart qbittorrent
```

### Radarr/Sonarr/Lidarr Can't Connect to qBittorrent

- Vérifier **Host** = `qbittorrent` (nom service, pas IP ou localhost)
- Vérifier **Port** = 8080 (interne, pas 8081)
- Vérifier même réseau Docker (`media-net`) — devrait être automatique via compose

### Downloads Stuck at 0%

- Vérifier seeds disponibles (torrent mort si 0 seeds)
- Vérifier port 6881 accessible (firewall, routeur)
- Essayer indexer différent (release peut être invalide)

### Slow Downloads

- Vérifier bande passante disponible (`Tools` → `Options` → `Speed` limits)
- Vérifier nombre connexions simultanées (`Options` → `Connection`)
- Indexer/tracker peut throttle (normal pour publics)

## Next Steps

1. Configurer categories + download clients (Radarr/Sonarr/Lidarr → qBittorrent)
2. Ajouter 1-2 indexers torrent par app
3. Test download 3-5 items (films/séries/musique)
4. Vérifier Plex/Jellyfin scan + affiche contenu
5. Proceed Étape 9 (Remote Access)

## Decision Notes

MVP = torrent-only (pas d'abonnement usenet). Architecture reste hybrid-ready : ajouter usenet plus tard = ajout service, aucune refonte.

Voir `docs/decisions/003-indexer-strategy-hybrid.md` (décision originale, adaptée ici pour phase MVP).
