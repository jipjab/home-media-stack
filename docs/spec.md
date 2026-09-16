# Spec — Home Media Stack

## Objectif

Déployer dual-stack Plex + Jellyfin + auto-download (films, séries, musique) pour famille 2-4 personnes, accessible localement et en remote sécurisé. VM Ubuntu + Docker. Contenu partagé, profils et accès distincts par stack. MVP dès septembre 2026.

## Périmètre

### Inclus (MVP)
- **Plex** : lecture films, séries, musique; profils utilisateur famille; Remote Access natif (sécurisé Plex)
- **Jellyfin** : lecture films, séries, musique; profils utilisateur distincts; accès local + remote HTTPS auto-signé
- **Contenu partagé** : même disque secondaire local pour Plex et Jellyfin (une seule source de vérité, `/home/media-stack`)
- **Auto-download** : capture automatique (Radarr/Sonarr/Lidarr ou alternatives) via torrent et/ou usenet, sans recherche manuelle
- **Stockage** : disque secondaire local (SSD, 1000G, `/dev/sdb` monté `/home/media-stack`), < 10 TB usage prévu (archive DVD/CD + acquisition future)
- **Gestion utilisateurs** : profils famille par stack, contrôles parentaux, quotas per-stack
- **Orchestration** : Docker Compose multi-service sur VM Ubuntu

### Exclus (v2)
- Emby (Plex + Jellyfin couvrent dual-stack)
- VPN/reverse proxy custom pour Plex (Remote Access suffisant); Jellyfin = HTTPS auto-signé
- Kubernetes/Swarm
- Sauvegarde automatique cross-site
- Scanner IP/port custom
- Monitoring avancé (Prometheus/Grafana)
- Synchronisation automatique métadonnées entre Plex et Jellyfin

## Audience

- **Utilisateurs** : Famille 2-4 personnes (enfants + adultes)
- **Cas d'usage** : Regarder films/séries en streaming personnel, lire musique, sans pub ni limitation
- **Attentes** : UI simple, découverte facile, pas de gestion manuelle des téléchargements

## Données & Contenus

- **Sources** : Archive DVD/CD (copies personnelles existantes) + auto-téléchargement
- **Répartition estimée** : Films ~5 TB, séries ~3 TB, musique ~1-2 TB
- **Formats supportés** : MKV, MP4, FLAC, MP3, autres (natifs Plex)
- **Qualité cible** : 1080p standard, 4K optionnel; aucune limite imposée

## Dépendances & Contraintes

### Techniques
- VM Ubuntu 22.04 LTS (ou 24.04)
- Docker Engine + Docker Compose
- Disque secondaire local partitionné, formaté ext4, monté `/home/media-stack`
- Licence Plex Media Server (déjà acquise)
- Connexion internet stable (pour auto-download et Remote Access)

### Temporelles
- MVP opérationnel **septembre 2026** (immédiat)
- Phase de test : 1 semaine

### Humaines
- Jip : déploiement infra + config
- Famille : validation UX et cas d'usage

### Décisions futures
- **Arr-stack vs alternatives** : évaluer lors de Phase 2
  - Radarr/Sonarr/Lidarr = référence, mature, large communauté
  - Overseerr/Jellyseerr = interfaces unifiées, mais plus jeunes
  - Choix : criterium = fiabilité auto-download + intégration Plex
- **Torrent vs Usenet** : pas de préférence actuellement; architecturer pour supporter les deux

## Risques & Hypothèses

| Risque | Mitigation |
|--------|-----------|
| Auto-download capture mauvaise qualité | Configurer listes d'exclusion/indexeurs fiables; validation avant ajout à Plex |
| Saturation bande passante (auto-DL + remote) | Scheduler downloads hors-heures; limiter nb connexions Plex + Jellyfin |
| Panne NAS = perte totale | RAID déjà en place; sauvegardes Plex + Jellyfin config sur VM |
| Conflit droits familiaux / accès parental | Profils séparés par stack, quotas per-app |
| Licence Plex expiration | Renouvellement manuel (pas d'auto-sub) = rappel calendrier |
| **Doublon transcoding** (Plex + Jellyfin lecture simultanée) | Limiter nb streams par utilisateur; CPU sufficient monitoring |
| **Métadonnées désync** (fichiers renommés, couvertures différentes) | Une source vérité NAS; Plex/Jellyfin opèrent indépendamment |
| **Profils dupliqués** (création compte × 2 apps) | Documentation claire pour famille; login séparé par app |

## Nice-to-have (v2+)

- Dashboard de monitoring (CPU, disque, bande passante)
- Backup cloud config Plex
- Intégration notifications (Telegram/Discord) téléchargements
- Optimisation qualité adaptive par connexion
- Gestion ACL granulaire par bibliothèque

## Critères de Succès

✅ Plex lancé, accessible local + remote  
✅ Au moins 3 films + 1 série + 10 albums dans Plex  
✅ Auto-download capte et catégorise 5+ items sur 1 semaine  
✅ Tous les profils famille se connectent et jouent  
✅ Pas d'intervention manuelle > 15 min/semaine après déploiement  
✅ Aucun crash > 24h de fonctionnement  

## Arborescence Projet

```
home-media-stack/
├── docs/
│   ├── spec.md (ce fichier)
│   ├── prompt_plan.md (Phase 2)
│   ├── todo.md (Phase 2)
│   └── decisions/
│       └── (registre de décisions, créé en Phase 1-2)
├── docker-compose.yml
├── .env.example
├── services/
│   ├── plex/
│   │   └── (config Plex, scripts init, Remote Access setup)
│   ├── jellyfin/
│   │   └── (config Jellyfin, scripts init, HTTPS cert auto-signé)
│   ├── radarr/
│   ├── sonarr/
│   ├── lidarr/
│   └── (autres apps)
├── scripts/
│   ├── install.sh
│   ├── backup.sh
│   └── health-check.sh
└── README.md
```

## Notes Techniques Préalables

- **Storage mount** : NAS monté comme `/mnt/media` sur VM; partagé Plex + Jellyfin (une seule source)
- **Env var** : `.env` contient credentials (Plex, Jellyfin, indexeurs, API keys)
- **Volumes Docker** : données persistent dans `/mnt/media/docker-data/`; configs séparées Plex/Jellyfin
- **Logs** : centralisés `/var/log/media-stack/` (+ stdout Docker)
- **Ports**:
  - Plex: 32400 (local + Remote Access natif)
  - Jellyfin: 8096 HTTP + 8920 HTTPS (auto-signé LAN)
  - Radarr: 7878, Sonarr: 8989, Lidarr: 8686 (bridge interne)
- **Transcoding** : CPU shared; limiter nb streams simultanés (configurable par app)
- **Certificat Jellyfin** : auto-signé généré à init; renouvellement annuel (script)
