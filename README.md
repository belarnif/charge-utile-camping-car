# Charge utile camping-car

Calculateur de charge utile pour camping-cars et fourgons aménagés.
Niche identifiée : problème réel (amendes, sécurité), faible concurrence
sur les stores, aucune app dédiée trouvée lors de l'étude de marché.

## Structure du projet

```
lib/
  main.dart                    -> point d'entrée, init RGPD/ATT/AdMob
  models/vehicle.dart          -> Vehicle (PTAC/PVOM) + ChargeItem
  services/
    charge_calculator.dart     -> logique de calcul + niveaux d'alerte
    storage_service.dart       -> sauvegarde locale du véhicule
  widgets/
    adaptive_banner_ad.dart    -> bannière AdMob adaptative/collapsible réutilisable
  screens/
    home_screen.dart           -> écran principal (formulaire + simulateur)
android/  -> config AndroidManifest.xml + build.gradle.kts (IDs de test AdMob)
ios/      -> config Info.plist (App ID, ATT, SKAdNetwork)
```

## Pour lancer le projet

1. Crée un nouveau projet Flutter vide : `flutter create charge_utile_app`
2. Remplace les fichiers générés par ceux de cette archive (lib/, pubspec.yaml,
   et fusionne android/ + ios/ avec ceux générés par `flutter create`)
3. `flutter pub get`
4. `flutter run`

## Avant publication sur les stores

- [ ] Créer l'app + l'unité publicitaire bannière dans la console AdMob
- [ ] Remplacer les IDs de test (`ca-app-pub-3940256099942544/...`) partout :
      AndroidManifest.xml, Info.plist, home_screen.dart (kBannerAdUnitId)
- [ ] Changer `applicationId` dans android/app/build.gradle
- [ ] Récupérer ton vrai testDeviceId dans les logs et le renseigner dans main.dart
- [ ] Vérifier la liste complète des SKAdNetworkIdentifier sur la doc Google
- [ ] Ajouter une icône d'app (actuellement non fournie)
- [ ] Tester le formulaire de consentement RGPD avec un compte de test EU

## Corrections suite à vérification (30/08/2026)

- `google_mobile_ads` mis à jour de `^5.1.0` (déprécié depuis Q1 2026) vers `^9.1.0`
  — vérifie la dernière version sur pub.dev au moment du build, ça évolue vite.
- `android/app/build.gradle` remplacé par `build.gradle.kts` (syntaxe Kotlin DSL,
  standard depuis Flutter 3.29). Si ton projet est encore en Groovy `.gradle`,
  adapte la syntaxe et ne mélange jamais les deux dans un même fichier.
- `ios/Runner/Info.plist` renommé en `.snippet` : c'était un extrait, pas un
  fichier complet. Ne jamais écraser ton Info.plist généré avec — fusionner
  uniquement les clés indiquées.
- **À vérifier toi-même avant publication** : `_requestTrackingIfNeeded()` dans
  `main.dart` est appelé avant `runApp()`. La doc officielle iOS recommande de
  déclencher la demande ATT après le premier rendu de l'UI (`addPostFrameCallback`)
  pour éviter un échec silencieux sur certains appareils. Teste sur un vrai
  iPhone avant de publier — si la boîte de dialogue ATT ne s'affiche pas,
  déplace cet appel dans `initState()` du `HomeScreen` avec un post-frame callback.

## Deuxième passe de corrections (30/08/2026)

- **`placesCarteGrise` était saisi mais jamais utilisé.** Le calcul ignorait
  complètement le nombre de places déclarées à la carte grise — pourtant en
  France, le nombre de passagers ne doit jamais dépasser ce nombre, indépendamment
  du poids. `ChargeCalculator` compare maintenant le nombre de passagers ajoutés
  (+1 pour le conducteur) aux places déclarées, et déclenche un niveau "danger"
  en cas de dépassement, avec un message dédié.
- Correction d'un **double-dispose potentiel** de la bannière AdMob dans
  `adaptive_banner_ad.dart` : en cas d'échec de chargement suivi d'un retry,
  l'ancienne référence pouvait être disposée deux fois. `_bannerAd` est
  maintenant remis à `null` avant le retry.
- Retrait de la valeur par défaut `4` sur le champ "nombre de places" —
  c'est une donnée de sécurité, elle ne doit jamais être pré-remplie avec
  une valeur arbitraire que l'utilisateur pourrait valider sans y penser.
- `cupertino_icons` et la contrainte `sdk` alignés sur le template Flutter
  actuel (Flutter 3.44, syntaxe `sdk: '^3.13.0'`).

## Troisième passe de corrections (30/08/2026)

- **`AndroidManifest.xml` était incomplet.** Il manquait `android:name="${applicationName}"`
  sur la balise `<application>` — un placeholder obligatoire, résolu par Gradle au
  moment du build, présent dans tout projet généré par `flutter create`. Sans lui,
  l'app risque de mal s'initialiser (le point d'entrée `Application` Android n'est
  pas correctement câblé). Il manquait aussi le `meta-data
  io.flutter.embedding.android.NormalTheme`, standard dans le template par défaut.
  Les deux sont ajoutés. Comme pour l'Info.plist, ce fichier reste à fusionner
  avec un projet déjà généré plutôt qu'à copier-coller aveuglément si tu as déjà
  un manifeste existant.

## Quatrième passe de corrections (30/08/2026)

- **Aucune validation de plage sur les champs numériques.** Rien n'empêchait
  d'enregistrer un véhicule avec un PTAC/PVOM négatif ou nul, un nombre de
  places à 0, ou d'ajouter un poste avec un poids négatif — ce qui aurait
  faussé silencieusement les calculs (et rendu inopérante l'alerte
  places/passagers ajoutée à la passe précédente). Ajout de contrôles
  simples : PTAC et PVOM doivent être positifs, places ≥ 1, poids d'un
  poste > 0.
- `flutter_lints` mis à jour de `^4.0.0` vers `^6.0.0` (3 versions majeures
  de retard — sans impact fonctionnel, juste des règles de style à jour).

## Cinquième passe de corrections (30/08/2026)

- **Fuite mémoire : aucun `TextEditingController` n'était disposé.** Ni les
  4 controllers de `_HomeScreenState` (PTAC, PVOM, nom, places), ni les 2 de
  `_AddItemDialogState` (libellé, poids) n'avaient de `dispose()` associé —
  chacun alloue des ressources natives qui doivent être libérées explicitement.
  Ajout des `dispose()` manquants dans les deux classes.

## Modèle économique

App gratuite, monétisée uniquement par la publicité AdMob (bannière
adaptative collapsible). Pas de système d'abonnement — décision volontaire
pour garder l'app 100% libre d'accès.

## Nouvelles fonctionnalités (30/08/2026) — basées sur les besoins réels des camping-caristes

Recherche faite dans les forums (campingcar-bricoloisirs, routard, ACCCF) sur les vraies
frustrations liées au poids. Trois besoins récurrents adressés :

- **La liste des postes de chargement est maintenant sauvegardée** entre les
  ouvertures de l'app (avant, elle se réinitialisait à chaque fermeture) —
  répond au besoin cité de "faire un inventaire régulier des affaires
  embarquées".
- **Convertisseur eau/gasoil → kg** dans le formulaire d'ajout de poste :
  saisis un volume en litres, le poids se calcule automatiquement
  (1 L d'eau = 1 kg, 1 L de gasoil ≈ 0,84 kg). Les gens réduisent leur eau
  embarquée "au pif" pour gagner du poids — ça leur donne un chiffre exact.
- **Bouton "Trouver un point de pesée à proximité"** : ouvre une recherche
  Google Maps ciblée (pont-bascule, déchetterie, garage). C'est la question
  la plus posée sur les forums camping-car concernant le poids — il n'existe
  pas de base de données fiable des ponts-bascules publics en France, donc
  on s'appuie sur les données déjà présentes dans Maps plutôt que d'inventer
  une liste de lieux non vérifiée.

- **`<queries>` ajouté au manifeste Android** pour garantir que le bouton
  "Trouver un point de pesée" (via `url_launcher`) fonctionne de façon
  fiable sur Android 11+ — un vieux souci connu du package sur certains
  appareils sans cette déclaration.
- **Message d'erreur ajouté** dans le formulaire d'ajout de poste : si le
  volume (eau/gasoil) ou le poids n'est pas renseigné, le bouton "Ajouter"
  affichait un échec silencieux — il indique maintenant clairement ce qui
  manque.

- **`codemagic.yaml` intégré à l'archive principale** — il avait été créé et
  transmis séparément lors du dépannage du build, sans jamais être ajouté au
  dossier principal du projet. Sans conséquence concrète (un `unzip -o`
  n'efface jamais de fichiers), mais l'archive était depuis incomplète par
  rapport à ce qui tourne réellement sur GitHub. C'est corrigé.
- **Clarification dans `android/app/build.gradle.kts`** : ce fichier n'est en
  réalité plus utilisé par le build Codemagic actuel (le script dans
  `codemagic.yaml` le régénère et l'écrase à chaque build) — il ne sert que
  de référence pour une compilation locale future.

## Fonctionnalités V1

- Saisie PTAC/PVOM/places (carte grise) avec sauvegarde locale
- Ajout de postes de chargement (passagers à 75kg, options, accessoires)
- Calcul en temps réel de la marge restante
- Vérification du nombre de passagers par rapport aux places déclarées à la carte grise
- Alerte visuelle (vert/orange/rouge) selon la marge de sécurité (100kg conseillés)
- Bannière AdMob adaptative, collapsible, avec gestion rotation + retry
