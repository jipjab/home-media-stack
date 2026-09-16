# 003 — Indexer Strategy: Hybrid (Usenet Primary + Torrent Fallback)

**Date:** 2026-09-16  
**Statut:** Adoptée (architecture) — **Déviation MVP:** Torrent-only en Phase 3 (pas d'abonnement usenet au moment du déploiement)

> **Note Phase 3** : Au moment de l'implémentation, aucun abonnement usenet actif. MVP déployé **torrent-only** (qBittorrent). Architecture reste hybrid-ready — usenet ajoutable sans refonte (voir `docs/setup-indexers.md`, section "Ajout Usenet Futur"). La stratégie hybrid ci-dessous reste la cible à terme.

## Contexte

Auto-download requiert source d'indexers : où trouver releases films/séries/musique.

Trois stratégies possibles :
1. **Torrent-only** : gratuit, large, mais plus lent, seeds variable
2. **Usenet-only** : rapide, fiable, mais requiert abonnement, moins de catalogues old
3. **Hybrid** : Usenet primaire (fiabilité), torrent fallback (couverture)

Utilisateur preference : aucune, décision ouverte.

## Décision

**Déployer Hybrid : Usenet primary → Torrent fallback.**

Configuration dans Radarr/Sonarr/Lidarr :
1. **Primary indexer** : Usenet (NZBgeek, Nzbndx, ou équivalent)
   - Vitesse 50+ MB/s (full disk saturation rare)
   - Reliabilité > 99% (releases archived années)
   - Cost: ~20 EUR/mois subscription

2. **Secondary indexer** : Torrent (Rarbg, TMDb, ou generic torrent)
   - Trigger si Usenet miss (rare)
   - Fallback couverture (old releases, niche, anime)
   - Cost: free (public indexers) ou seed contrib

3. **Quality gates** :
   - Usenet: download auto si score > 90 (nuked detection built-in)
   - Torrent: download si seeds > 20 (deadweight filter) + âge < 30j (fresh sourced)

## Rationale

- **Usenet fiabilité** : 20+ ans d'archive, moins de DMCA takedown que torrent
- **Torrent couverture** : catch indexer miss, anime niche, old catalogs
- **Zero configuration burden** : arr-stack gérera fallback auto; user n'intervient pas
- **Cost balance** : Usenet sub mini, torrent gratuit = affordable hybrid
- **Speed** : Usenet primaire = fast (90% cas); torrent fallback = acceptable (10% cas)

## Conséquences

✅ **Avantages**
- Fiabilité max (Usenet primary)
- Couverture max (Torrent fallback)
- Configuration simple (set + forget)
- Coût minimum (Usenet sub ~20 EUR + free torrent)

⚠️ **Coûts**
- Dépendance Usenet subscription (renewal nécessaire)
- Deux sources = légère augmentation CPU indexer search
- Usenet ISP blocking possible (rare, VPN mitigate)

## Ce qui ferait changer d'avis

1. **Usenet subscription coûteux / inaccessible** → torrent-only pivot
   - Mitigation: garder torrent indexer configuré (fallback fonctionne déjà)
   
2. **Indexer Usenet fiabilité dégrada** (ISP blocking, provider failure) → ajouter 2e Usenet indexer ou flip torrent-primary

3. **User préfère torrent-only** (politique personnelle, open-source purity) → redeploy torrent-only, rebrand decision

4. **CPU saturation** dual-search → simplify torrent-only (saves 5-10% CPU indexing)

## Dépendances

- Décision 002 : arr-stack choice **confirme** cette architecture (chaque app supporte hybrid)
- Étape 8 (Phase 3) : configuration API Radarr/Sonarr/Lidarr indexers → implémente ce plan

## Notes Techniques

**Usenet config** :
- Indexer URL : NZBgeek / Nzbndx / similaire
- API key : depuis provider account
- Downloader : SABnzbd ou NZBGet container

**Torrent config** :
- Generic indexer (Rarbg via API, TMDb, ou custom torrent site)
- Quality gates : min 20 seeds, max 30 jours âge
- Downloader : transmission ou qBittorrent container (optionnel, peut être host)

**Fallback logic** :
- Radarr/Sonarr/Lidarr : ajouter Usenet + Torrent indexers
- Priority : Usenet score 100, Torrent score 50 (Usenet sempre searched first)
- Radarr/Sonarr only download Torrent si Usenet zero hits (automatique)
