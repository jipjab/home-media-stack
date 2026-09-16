# 002 — Arr-Stack: Radarr + Sonarr + Lidarr

**Date:** 2026-09-16  
**Statut:** Adoptée

## Contexte

MVP auto-download requiert 3 applications : films, séries, musique. Alternatives :
- **Arr-Stack** (Radarr + Sonarr + Lidarr) : mature, modular, large community, native Plex integration
- **Jellyseerr / Overseerr** : unified UI, mais jeune ecosystem, moins de features granulaires
- **Manual curl + NZB client** : minimum viable, très limité

## Décision

**Déployer Radarr + Sonarr + Lidarr** (arr-stack classique).

- Radarr : films, quality profiles granulaires, Plex root folder integration native
- Sonarr : séries, episode tracking, release timing, anime support optionnel
- Lidarr : musique, Musicbrainz metadata, FLAC vs MP3 profiles

Pas d'unification UI (Overseerr/Jellyseerr en v2 possible). Trois UIs séparées = plus de configuration initiale, mais chacun optimisé son domaine.

## Rationale

- **Maturité** : arr-stack > 10 ans, 1000+ GitHub stars, bug fixes constants
- **Indexer support** : torrent + usenet + hybrid nativement; fallback automatique
- **Plex integration** : scan root folder auto, import metadata directe
- **Granularité** : quality profiles par type (1080p films, 720p séries, FLAC musique) sans compromise
- **Failover** : indexer dead → app cherche next candidate auto (zéro friction)
- **Feature parity** : tout ce qui existe chez Overseerr existe chez arr-stack; inverse faux

## Conséquences

✅ **Avantages**
- Chaque app optimale dans son domaine
- Community large = support + fixes rapides
- Aucun vendor lock-in (open-source)
- Fallback indexer automatique built-in

⚠️ **Coûts**
- Trois UIs = trois onboardings (mitigé par docs + setup scripts)
- Configuration répétitive (settings par app au lieu de centralisé)
- Plus de CPU (3 processes vs 1)

## Ce qui ferait changer d'avis

1. **Overseerr / Jellyseerr maturent** + unified UI surpasse arr-stack modularity → possible migration v2, mais zéro urgence
2. **CPU constraint** après test → réduire à 1-2 apps (films seul?) ou migrate vers solution légère
3. **Indexer intégration cassée** dans arr-stack (exemple: Usenet soudain infiable) → parallel avec alternative
4. **Plex stops root-folder scan** → fallback manual sync ou script custom

## Dépendances

- Décision 003 : stratégie indexer (torrent vs usenet vs hybrid) **confirme** ce choix
  - Arr-stack supporte tout = choix d'indexer n'impacte pas architecture
