# Audit standards — App Mindiff

Analyse du respect des normes WCAG, OWASP, GreenIT et ISO 25010 sur le code existant.
Pour chaque point : ✅ respecté / ⚠️ partiellement / ❌ non respecté.

---

## WCAG — Accessibilité

> Web Content Accessibility Guidelines. Niveau AA visé (standard minimum).

### ✅ Ce qui est en place

| Point | Détail |
|---|---|
| Champs mot de passe masqués | `obscureText: true` sur tous les champs password (`login_page.dart`, `register_onboarding_page.dart`) |
| Type de clavier adapté | `keyboardType: TextInputType.emailAddress` sur les champs email |
| Validation des formulaires | Validators sur tous les formulaires avec messages d'erreur explicites |
| Mode sombre | Thème clair/sombre complet via `MyThemeMode` + `THelperFunctions.isDarkMode()` |
| Synthèse vocale | `FlutterTts` intégré sur la page caméra avec guidage vocal des exercices en français |
| Tooltips | Présents sur certains boutons (`tooltip: 'Rafraîchir'`, `tooltip: 'Retour à la connexion'`) |

### ⚠️ Points à améliorer

| Problème | Détail | Critère WCAG |
|---|---|---|
| Couleur primaire insuffisante | `#A2B4EC` sur fond blanc = ratio ~2.4:1. Le minimum AA est 4.5:1 pour le texte normal | 1.4.3 Contraste |
| Pas de `Semantics` widgets | Les lecteurs d'écran (TalkBack/VoiceOver) ne peuvent pas décrire la plupart des éléments interactifs | 4.1.2 Nom, rôle, valeur |
| Images réseau sans label | Les 3 `Image.network` dans `home_page.dart` et `programme_page.dart` n'ont pas de `semanticLabel` | 1.1.1 Contenu non textuel |
| Tailles de texte fixes | 125 occurrences de `fontSize` en valeurs px fixes, sans respect du facteur de zoom système (`textScaler`) | 1.4.4 Redimensionnement du texte |

---

## OWASP — Sécurité

> OWASP Top 10 — les 10 risques de sécurité les plus critiques.

### ✅ Ce qui est en place

| Point | Détail |
|---|---|
| Mots de passe hashés avec bcrypt | `bcrypt.hashpw()` + `bcrypt.gensalt()` dans `security.py`. bcrypt est recommandé par OWASP (A02) |
| JWT avec expiration | Token expirant après 30 min (`ACCESS_TOKEN_EXPIRE_MINUTES = 30`) |
| Révocation automatique du token | En cas de 401, le token est effacé et l'utilisateur redirigé vers le login (A07) |
| Timeout réseau | 10 secondes sur tous les appels HTTP — protection contre les requêtes pendantes |
| Secrets via HashiCorp Vault | Les clés d'API et secrets ne sont pas hardcodés dans le code (A05) |
| Validation côté front | Formulaires avec validators (email, mot de passe, données numériques) |
| Autorisation vérifiée côté back | Les endpoints vérifient `current_user.id == user_id` avant d'accéder aux données (A01) |

### ⚠️ Points à améliorer

| Problème | Détail | Criticité |
|---|---|---|
| CORS `allow_origins=["*"]` | `main.py` ligne 35 — accepte les requêtes de n'importe quelle origine. En production, restreindre à l'URL de l'app (A05) | Haute |
| JWT dans SharedPreferences | Non chiffré sur le disque Android/iOS. Préférer `flutter_secure_storage` qui utilise le Keystore système (A02) | Moyenne |
| Pas de rate limiting sur `/auth/login` | Aucune limite sur les tentatives de connexion → risque de brute force (A07) | Moyenne |
| URL backend en HTTP | `http://localhost:8082` en développement. S'assurer que l'URL de production utilise HTTPS | Basse (dev) |
| `debugPrint` en production | 14 occurrences dans le code — peut exposer des données dans les logs (A09) | Basse |

---

## GreenIT — Éco-conception logicielle

> Principes de conception sobre : réduire la consommation réseau, mémoire et CPU.

### ✅ Ce qui est en place

| Point | Détail |
|---|---|
| Libération des ressources | `dispose()` correctement appelé sur tous les `TextEditingController` et controllers GetX |
| Fenêtre d'historique limitée | L'historique de poids est limité à 28 entrées côté affichage — pas de chargement infini |
| Timeout réseau systématique | Évite les requêtes zombies qui consomment batterie et réseau |
| Lazy loading GetX | Les contrôleurs sont instanciés à la demande, pas tous au démarrage |
| Limite sur les requêtes d'exercices | `limit=50` par défaut sur `getExercises()` — pas de chargement de catalog entier |

### ⚠️ Points à améliorer

| Problème | Détail | Impact |
|---|---|---|
| Aucun cache des données métier | Chaque navigation vers une page recharge les données depuis l'API (repas, poids, workout). Pas de cache local ni HTTP | Réseau |
| `Image.network` sans cache disque | Flutter a un cache mémoire natif mais pas de cache disque. Les images Edamam sont re-téléchargées à chaque session. Utiliser `cached_network_image` | Réseau |
| Caméra ML Kit en continu | L'analyse de pose tourne frame par frame sans pause même en dehors des exercices actifs | CPU / Batterie |
| `debugPrint` actifs | 14 appels en production — overhead d'I/O inutile à désactiver en release | CPU |
| Pas de pagination sur les listes | Les suggestions de repas et exercices chargent tout d'un coup sans pagination | Réseau / Mémoire |

---

## ISO 25010 — Qualité logicielle

> Norme de qualité software : maintenabilité, fiabilité, performance, sécurité, portabilité.

### ✅ Ce qui est en place

| Caractéristique | Point | Détail |
|---|---|---|
| **Maintenabilité** | Architecture Clean | Le feature `user_profile` respecte la séparation domain / data / presentation |
| **Maintenabilité** | Séparation des responsabilités | Services, contrôleurs et pages ont des rôles distincts |
| **Fiabilité** | Tests unitaires | 28 tests unitaires couvrant les modèles, entités, repository et cubit (`test/unit/`) |
| **Fiabilité** | Gestion d'erreurs HTTP | `ApiClient` centralise la gestion des codes d'erreur et du 401 |
| **Portabilité** | Multi-plateforme | Flutter cible iOS, Android, Web, Desktop depuis un code unique |
| **Sécurité** | Voir section OWASP | — |

### ⚠️ Points à améliorer

| Caractéristique | Problème | Détail |
|---|---|---|
| **Maintenabilité** | Architecture incohérente entre features | `user_profile` utilise Clean Architecture, mais `nutrition`, `workout`, `balance` mettent toute la logique directement dans les pages |
| **Maintenabilité** | Deux couches d'accès aux données | `UserDataSourceImpl` accède à PostgreSQL en direct via `package:postgres`, pendant que tout le reste passe par l'API REST — deux approches qui coexistent sans raison claire |
| **Fiabilité** | Pas de tests d'intégration | Les appels API réels ne sont pas testés |
| **Fiabilité** | `debugPrint` dans le code de production | Ne devrait pas être présent dans une build release |
| **Maintenabilité** | `ProfileState` sans `==` | Rend le débogage et le test plus complexes (contournement nécessaire avec `isA<>()`) |

---

## Résumé

| Norme | État global | Principaux points forts | Principal point faible |
|---|---|---|---|
| **WCAG** | ⚠️ Partiel | Mode sombre, TTS, validation | Contraste couleur primaire insuffisant |
| **OWASP** | ⚠️ Partiel | bcrypt, JWT, Vault, autorisation | CORS wildcard, token non chiffré |
| **GreenIT** | ⚠️ Partiel | dispose(), timeout, limites | Aucun cache des données métier |
| **ISO 25010** | ⚠️ Partiel | Tests unitaires, architecture service | Incohérence architecturale entre features |
