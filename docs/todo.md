# TODO — Home Media Stack

Phase 2 execution checklist. Check items as Phase 3 progresses.

## Setup & Core Infra

- [ ] **Étape 1** : Setup VM Ubuntu + Docker
  - [ ] install.sh écrit + testé
  - [ ] Docker Engine 24.x+ installé
  - [ ] Docker Compose v2 opérationnel
  - [ ] NAS monté `/mnt/media`, accessible
  - [ ] `.env` template créé

- [ ] **Étape 2** : Skeleton Docker Compose + Network
  - [ ] `docker-compose.yml` syntaxe valide
  - [ ] Réseau "media-net" défini
  - [ ] Volumes config + media mapped
  - [ ] Service stubs tous présents
  - [ ] `docker-compose.override.yml` (dev) créé

## Media Servers

- [ ] **Étape 3** : Service Plex — Docker Image + Config
  - [ ] Plex image config dans compose
  - [ ] Port 32400 accessible
  - [ ] Web UI répond
  - [ ] Auth token valid (PLEX_CLAIM OK)
  - [ ] Bibliothèques NAS scannées
  - [ ] `docs/setup-plex.md` écrit

- [ ] **Étape 4** : Service Jellyfin — Docker Image + Config
  - [ ] Jellyfin image config dans compose
  - [ ] Ports 8096 + 8920 accessibles
  - [ ] Certificat auto-signé généré
  - [ ] Web UI répond (HTTP + HTTPS)
  - [ ] Bibliothèques NAS scannées (parallèle Plex)
  - [ ] `docs/setup-jellyfin.md` écrit

## Auto-Download Stack

- [ ] **Étape 5** : Radarr — Films
  - [ ] Radarr image config, port 7878
  - [ ] Indexer(s) configuré(s)
  - [ ] Quality profiles définis
  - [ ] `/mnt/media/films` créé et pointé
  - [ ] Test manual add film → download OK
  - [ ] `docs/setup-radarr.md` écrit

- [ ] **Étape 6** : Sonarr — Séries
  - [ ] Sonarr image config, port 8989
  - [ ] Indexer(s) configuré(s)
  - [ ] Quality profiles définis
  - [ ] `/mnt/media/series` créé et pointé
  - [ ] Test manual add série → download OK
  - [ ] `docs/setup-sonarr.md` écrit

- [ ] **Étape 7** : Lidarr — Musique
  - [ ] Lidarr image config, port 8686
  - [ ] Indexer torrent configuré
  - [ ] Quality profiles définis (FLAC/MP3)
  - [ ] `/mnt/media/music` créé et pointé
  - [ ] Test manual add artiste → download OK
  - [ ] `docs/setup-lidarr.md` écrit

- [ ] **Étape 8** : Auto-Download Config — Indexers
  - [ ] Indexer choice documenté (torrent/usenet/hybrid)
  - [ ] Radarr + Sonarr + Lidarr indexers actifs
  - [ ] Quality gates appliquées
  - [ ] Manual search teste dans chaque app
  - [ ] `docs/setup-indexers.md` écrit
  - [ ] `scripts/setup-indexers.sh` créé

## Remote Access & Users

- [ ] **Étape 9** : Remote Access — Plex Remote + Jellyfin HTTPS
  - [ ] Plex Remote Access green (Settings check)
  - [ ] Plex accessible externe (test mobile hotspot)
  - [ ] Jellyfin HTTPS fonctionnel (port 8920)
  - [ ] Certificat auto-signé OK (ignore warning)
  - [ ] Port forward routeur configuré (32400 si needed)
  - [ ] `docs/setup-remote-access.md` écrit
  - [ ] `scripts/test-remote.sh` créé

- [ ] **Étape 10** : Profils Utilisateurs Famille
  - [ ] Profils Plex créés (admin + family)
  - [ ] Profils Jellyfin créés (admin + family)
  - [ ] Parental controls testés
  - [ ] Watchlist séparé per profil
  - [ ] Restricted content hidden for child
  - [ ] `docs/setup-family-profiles.md` écrit
  - [ ] `docs/FAMILY-GUIDE-FR.md` écrit

## Management UI

- [ ] **Étape 14** : Docker Management UI — Arcane
  - [ ] Arcane image config dans compose, port 8080
  - [ ] Docker socket mounted (read-only)
  - [ ] Web UI accessible (http://localhost:8080)
  - [ ] Tous services visibles dans dashboard (Plex, Jellyfin, Radarr, Sonarr, Lidarr)
  - [ ] Logs temps-réel fonctionnels
  - [ ] CPU/Memory monitoring actif
  - [ ] `docs/setup-arcane.md` écrit
  - [ ] `ARCANE_SECRET` ajouté à `.env.example`

## Testing & Documentation

- [ ] **Étape 11** : Tests End-to-End + Monitoring
  - [ ] Scenario 1: manual add → auto-download → Plex playback OK
  - [ ] Scenario 2: Jellyfin playback same film OK
  - [ ] Scenario 3: remote Plex access testé
  - [ ] Scenario 4: famille profiles tested + restricted content works
  - [ ] Log rotation setup
  - [ ] Cron jobs pour health checks
  - [ ] `docs/testing.md` écrit
  - [ ] `scripts/health-check.sh` créé + fonctionnel
  - [ ] `scripts/setup-monitoring.sh` créé

- [ ] **Étape 12** : Documentation Complète + Runbooks
  - [ ] `README.md` (quick start)
  - [ ] `docs/ARCHITECTURE.md` (diagram + flow)
  - [ ] `docs/TROUBLESHOOTING.md` (5+ issues + fixes)
  - [ ] `docs/MAINTENANCE.md` (weekly/monthly tasks)
  - [ ] `docs/API-SETUP.md` (API keys + examples)
  - [ ] `scripts/troubleshoot.sh` créé + testé

- [ ] **Étape 15** : Final Cleanup + Arborescence
  - [ ] Arborescence conforme structure projet
  - [ ] `.gitignore` couvre .env, docker-data/, logs/
  - [ ] Tous scripts `chmod +x`
  - [ ] Zero hardcoded secrets
  - [ ] `git status` clean
  - [ ] Commit structure finale

## Decision Records

- [ ] **001 — Dual-Stack Plex + Jellyfin** : ✅ Enregistrée (docs/decisions/001-dual-stack-plex-jellyfin.md)
- [ ] **002 — Arr-Stack Choice** : ✅ Enregistrée (docs/decisions/002-arr-stack-choice.md)
- [ ] **003 — Indexer Strategy** : ✅ Enregistrée (docs/decisions/003-indexer-strategy-hybrid.md)

## Summary

**15 étapes** (14 services + setup, 1 cleanup final), chacune autonome, testable, avec critères validation clairs.

**Langage cible Phase 3** : Français (docs, specs), English (code, filenames, identifiers).

**Validation**: cocher items à mesure; si blocage → documenter dans decision record.
