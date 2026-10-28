# 🏴‍☠️ SkullCount — Compteur & Journal de Bord Skull King (Édition Classique)

Application iOS native complète développée en **Swift 5.9+**, **SwiftUI**, **SwiftData** et **Swift Charts** (iOS 17+ minimum), sans aucune dépendance externe.

---

## 🧭 1. Architecture & Arborescence du Projet

L'architecture suit le patron **MVVM (Model-View-ViewModel)** avec séparation stricte des responsabilités (services purs testables, modèles de données SwiftData, DTOs de sérialisation et composants d'interface).

```text
SkullCount/
├── Sources/
│   └── SkullCount/
│       ├── SkullCountApp.swift               # Point d'entrée de l'application & ModelContainer SwiftData
│       │
│       ├── Models/                           # Modèles de persistance SwiftData
│       │   ├── Enums.swift                   # RoundMode, GameStatus
│       │   ├── Player.swift                  # Entité Joueur (nom, couleur hex, emoji, archivage)
│       │   ├── Game.swift                    # Entité Partie (statut, dates, bonus, rotation, tags)
│       │   ├── GameParticipant.swift         # Joueur participant, siège, rang et score final
│       │   ├── Round.swift                   # Manche (numéro, cartes distribuées, premier joueur)
│       │   └── RoundEntry.swift              # Saisie manche (pari, plis, bonus, cumul)
│       │
│       ├── Services/                         # Moteurs de calcul et logique métier pure
│       │   ├── ScoringEngine.swift           # Moteur pur de calcul des scores et rotations
│       │   ├── RatingService.swift           # Calcul du classement ELO multijoueur (duels 2 à 2)
│       │   ├── StatsService.swift            # Faits marquants, psychologie des paris, profils, face-à-face
│       │   ├── RecordsService.swift          # Hall of Fame, Hall of Shame et Badges
│       │   ├── ExportImportService.swift     # Export/Import JSON & CSV avec fusion UUID
│       │   └── DemoDataGenerator.swift       # Générateur de 20 parties réalistes de test
│       │
│       ├── DTOs/                             # Objets de transfert pour JSON / Export
│       │   └── ExportDTOs.swift              # SkullKingExportDTO, PlayerDTO, GameDTO, RoundDTO
│       │
│       ├── Theme/                            # Charte graphique & thème pirate sobre
│       │   └── PirateTheme.swift             # Couleurs (Bleu nuit, Or, Parchemin), palettes, hex
│       │
│       ├── ViewModels/                       # États réactifs de saisie
│       │   └── GamePlayViewModel.swift       # Saisie 1-tap, contrôle en direct, annulation, calculs
│       │
│       └── Views/                            # Vues SwiftUI
│           ├── HomeDashboardView.swift       # Accueil, reprise automatique, raccourcis
│           ├── NewGameSetupView.swift        # Config express (<15s), sélection rapide, boussole
│           ├── RoundPlayView.swift           # Écran de jeu optimisé (saisie ultra-rapide)
│           ├── ScoresTableView.swift         # Tableau complet des scores manche par manche
│           ├── GameResultView.swift          # Révélation du trésor, suspense, podium, partage
│           ├── StatsDashboardView.swift      # Hub complet des statistiques (5 onglets)
│           ├── PlayersListView.swift         # Gestion de l'équipage (édition, archivage)
│           ├── RulesReferenceView.swift      # Aide-mémoire 66 cartes et hiérarchie
│           ├── SettingsView.swift            # Export/Import JSON/CSV, mode démo secret
│           │
│           └── Components/                   # Composants visuels réutilisables
│               ├── PirateComponents.swift    # Boutons numérotés 44pt+, cartes vitrées
│               ├── StartingPlayerWheelView.swift # Boussole animée de tirage au sort
│               ├── BonusCaptureSheet.swift   # Feuille modale de saisie des bonus
│               └── GameChartsView.swift      # Graphiques Swift Charts (scores, bump chart, etc.)
│
└── Tests/
    └── SkullCountTests/
        └── ScoringEngineTests.swift          # Tests unitaires XCTest (100% des cas obligatoires)
```

---

## ⚡️ 2. Points Forts de l'Implémentation

### 1. Rapidité de saisie extrême (0 clavier)
- **Phase 1 (Paris)** : Chaque joueur dispose d'une rangée de pastilles rondes tactiles (taille `≥ 44 pt`). 1 tap = pari validé. L'indicateur dynamique calcule instantanément la surenchère ou sous-enchère de table.
- **Phase 2 (Résultats)** : Bouton « ✓ Réussi » sur chaque ligne pour régler en 1 tap `plis = pari`. Bouton global « Tous réussi ».
- **Aide intelligente** : Quand il ne reste qu'un joueur à saisir, l'application pré-remplit ou propose immédiatement la seule valeur possible `(cartesDistribuées - sommeDesPlis)`.
- Contrôle strict : `somme(plis) == cartesDistribuées`.

### 2. Moteur de Score Pur & Conforme (`ScoringEngine`)
- **Édition Classique Schmidt (66 cartes)** :
  - Pari $\ge 1$ réussi $\rightarrow +20 \times \text{pari} + \text{bonus}$
  - Pari $\ge 1$ raté $\rightarrow -10 \times |\text{plis} - \text{pari}|$ (aucun bonus)
  - Pari $0$ réussi $\rightarrow +10 \times \text{cartesDistribuées} + \text{bonus}$
  - Pari $0$ raté $\rightarrow -10 \times \text{cartesDistribuées}$ (aucun bonus)
  - Bonus de capture (Skull King capturant Pirate $+30$, Sirène capturant Skull King $+50$) uniquement si le pari est réussi.
- **Rotation mathématique** :
  $$\text{firstPlayerIndex}(\text{manche } r) = (\text{startingIndex} + (r - 1)) \pmod{\text{nbJoueurs}}$$
- **Modes de manches** :
  - *Manches réduites* (défaut) : nombre de manches = $\min(10, \lfloor \text{taillePaquet} / \text{nbJoueurs} \rfloor)$.
  - *10 manches plafonnées* : toujours 10 manches avec cartes plafonnées.

### 3. Statistiques & Swift Charts très poussés
1. **Partie** : Courbe des scores cumulés, *Bump Chart* d'évolution des rangs à chaque manche, histogrammes de points gagnés/perdus, comparaison des paris de table vs cartes.
2. **Profil Joueur** : ELO, taux de réussite global et par nombre de cartes, calcul du **biais psychologique** (« Tu te sous-estimes » / « Tu te surestimes »), spécialiste du 0, précision à $\pm 1$ pli, plus longue série de réussites.
3. **Face-à-Face** : Bilans directs A vs B, effet de présence (score de A avec et sans B).
4. **Classement Général** : Algorithme **ELO multijoueur** avec évolution match par match, pourcentages de victoires, rang normalisé.
5. **Hall of Fame & Badges** : Plus gros trésor, pire naufrage ($-100$ pts ou pire), victoire la plus serrée, badges « Pari Parfait », « Roi du Zéro », etc.

### 4. Export / Import JSON & CSV
- Export JSON complet de la base avec version de schéma `1`, dates ISO8601 et DTOs découplés de SwiftData.
- Import avec deux modes : **Fusion intelligente par UUID** (sans doublons) ou **Remplacement intégral**.
- Export CSV avec 1 ligne par manche et par joueur pour analyse tableur externe.

---

## 🛠️ 3. Lancement & Données de test

1. Ouvrez le projet dans **Xcode 15+** avec iOS 17 minimum.
2. Lancez sur Simulateur iPhone (ou appareil réel).
3. **Données de démonstration instantanées** :
   - Allez dans **Réglages** puis tapez **5 fois** sur le texte de version `SkullCount v1.0.0` en bas.
   - 20 parties réalistes et 8 pirates de légende seront automatiquement injectés dans SwiftData !
4. **Exécution des tests unitaires** :
   - Appuyez sur `⌘ + U` dans Xcode pour exécuter `ScoringEngineTests`.
