# 001 — Dual-Stack Plex + Jellyfin

**Date:** 2026-09-16  
**Statut:** Adoptée

## Contexte

Besoin de lecteur media famille accessible local + remote. Plex licence déjà acquise, interface établie. Jellyfin alternatif open-source sans compte obligatoire, contrôle total localement.

## Décision

Déployer **Plex ET Jellyfin en parallèle** sur même contenu NAS.

- Plex = accès remote (Plex Remote Access natif), profils famille, UI établie
- Jellyfin = accès local sécurisé (HTTPS auto-signé), indépendance de compte centralisé, flexibilité ouverte

Même source contenu (`/mnt/media`). Profils et métadonnées gérées indépendamment par stack.

## Rationale

- **Hedge against vendor** : Plex peut changer termes/pricing; Jellyfin open garantit continuité
- **Flexibilité profils** : famille teste Plex remote, local Jellyfin; libertée de switch si l'une déçoit
- **Pas de verrouillage** : zéro re-encoding ou migration si l'une abandonne
- **Charge CPU acceptable** : dual transcoding seulement si lecture simultanée (rare); limitable par config

## Conséquences

✅ **Avantages**
- Aucune dépendance unique vendor
- Profils séparés = plus de flexibilité d'accès per-utilisateur
- Test utilisateur real de deux modèles

⚠️ **Coûts**
- CPU doublon si lecture simultanée (mitigation: limiter streams)
- Deux UIs à maintenir/documenter pour famille
- Métadonnées indépendantes = possibilité désync couvertures/descriptions (mineur, chacun scanne indépendamment)

## Ce qui ferait changer d'avis

1. **Jellyfin abandonne support** → repli sur Plex seul, ou migration Emby/autre
2. **CPU insufficient** après 2-3 mois test → réduire Jellyfin à local-only, kill remote; ou boost VM
3. **Famille préfère une seule UI** → disable une stack après test 4 semaines; probablement Jellyfin (plus jeune)
4. **Plex change modèle licensing** → possible tipping point vers Jellyfin full-time

## Décisions Dépendantes

- 002 (à venir) : Auto-download orchestration (arr-stack ou alternative)
- 003 (à venir) : Torrent + Usenet fallback config
