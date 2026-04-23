# Référence des services & appels de données — App Mindiff

Ce document liste **toutes les fonctions existantes** pour accéder aux données dans l'app.
Avant d'écrire un nouvel appel API ou une nouvelle méthode de données, vérifie ici si elle existe déjà.

---

## Comment accéder aux services (GetX)

Tous les services et contrôleurs sont enregistrés globalement via GetX. Pour les utiliser dans n'importe quelle page ou widget :

```dart
final auth    = Get.find<AuthService>();
final profile = Get.find<UserProfileController>();
final programme = Get.find<ActiveProgrammeController>();
```

`AuthService` est le point d'entrée unique pour **tous les appels réseau**.
Ne jamais utiliser `ApiClient` directement depuis une page.

---

## AuthService — `lib/services/auth_service.dart`

### Authentification

| Méthode | Endpoint | Description |
|---|---|---|
| `register({email, password, name})` | `POST /auth/register` | Crée un compte. Le `username` est dérivé automatiquement du nom ou de l'email. Retourne `Map<String, dynamic>`. |
| `login({email, password})` | `POST /auth/login` | Connecte l'utilisateur et **stocke le JWT automatiquement** dans SharedPreferences. Retourne `Map<String, dynamic>` avec `access_token`. |
| `getCurrentUser()` | `GET /auth/me` | Récupère le profil complet de l'utilisateur connecté. Retourne `Map<String, dynamic>`. |
| `logout()` | *(local)* | Efface le JWT de SharedPreferences. Pas d'appel réseau. |

---

### Profil utilisateur

| Méthode | Endpoint | Description |
|---|---|---|
| `updateUserProfile(userId, {email, username, weight?, height?, age?, gender?, sportObjective?, targetWeight?, sessionsPerWeek?, healthConsiderations?})` | `PUT /user/{userId}` | Met à jour le profil complet. Les métriques (weight, height, age) sont regroupées dans un sous-objet `metrics` et **ne sont envoyées que si les 3 sont fournis simultanément**. |

---

### Poids

| Méthode | Endpoint | Description |
|---|---|---|
| `getWeightHistory(userId)` | `GET /user/{userId}/weight-history` | Retourne `List<Map>` avec les champs `date` (String ISO) et `weight` (num) et `source` (String). |
| `addWeight(userId, weight, {source})` | `POST /user/{userId}/weight` | Ajoute une pesée. `source` vaut `'manual'` par défaut. Pas de valeur de retour. |

---

### Nutrition / Repas

| Méthode | Endpoint | Description |
|---|---|---|
| `getMeals(userId, {date?})` | `GET /user/{userId}/meals?date=YYYY-MM-DD` | Repas du jour (ou d'une date donnée). Si `date` est null, utilise aujourd'hui. Retourne `Map<String, dynamic>`. |
| `addMeal(userId, {mealType, description, date?, calories?, proteinG?, fatG?, carbsG?, fiberG?})` | `POST /user/{userId}/meals` | Ajoute un repas. Les macros sont optionnelles mais si `calories` est fourni, les 4 macros sont envoyées (0.0 si non renseignées). Retourne `Map<String, dynamic>`. |
| `deleteMeal(userId, mealId)` | `DELETE /user/{userId}/meals/{mealId}` | Supprime un repas. Pas de valeur de retour. |
| `getMealSuggestions(userId)` | `GET /user/{userId}/dashboard/meal-suggestions` | Suggestions de repas basées sur le TDEE et les repas déjà loggés. Retourne `Map<String, dynamic>` avec `tdee`, `consumed_today`, `remaining` et `suggestions`. |

---

### Workout / Programme

| Méthode | Endpoint | Description |
|---|---|---|
| `getCurrentWorkout(userId)` | `GET /user/{userId}/workout/current` | Plan de la semaine actuel généré par le backend. Retourne `Map<String, dynamic>`. |
| `regenerateWorkout(userId)` | `POST /user/{userId}/workout/regenerate` | Regénère un nouveau plan (remplace l'actuel). Retourne `Map<String, dynamic>`. |
| `pinWorkout(userId, workoutWeekId)` | `POST /user/{userId}/workout/current/pin?workout_week_id={id}` | Épingle un plan pour le garder même lors d'une future regénération. Retourne `Map<String, dynamic>`. |
| `createCustomWorkout(userId, {name, exercises})` | `POST /user/{userId}/workout/custom` | Crée un programme personnalisé. `exercises` est une `List<Map<String, dynamic>>`. Retourne `Map<String, dynamic>`. |
| `getCustomWorkouts(userId)` | `GET /user/{userId}/workout/custom` | Liste tous les programmes custom de l'utilisateur. Retourne `List<dynamic>`. |
| `deleteCustomWorkout(userId, workoutId)` | `DELETE /user/{userId}/workout/custom/{workoutId}` | Supprime un programme custom. Pas de valeur de retour. |

---

### Exercices

| Méthode | Endpoint | Description |
|---|---|---|
| `getExercise(exerciseId)` | `GET /exercise/{id}` | Détail d'un exercice par son ID (encodé URI). Retourne `Map<String, dynamic>`. |
| `getExercises({target?, bodyPart?, equipment?, q?, limit})` | `GET /exercise/?...` | Liste d'exercices filtrés. Si `q` est fourni, utilise la recherche textuelle (`/exercise/filter?q=...`). `limit` vaut 50 par défaut. Retourne `List<dynamic>`. |

---

## UserProfileController — `lib/controllers/user_profile_controller.dart`

Contrôleur **global GetX** qui stocke en mémoire (et dans SharedPreferences) les données de l'utilisateur connecté. Pas d'appel réseau direct — il consomme les réponses de `AuthService`.

### Données observables

| Propriété | Type | Contenu |
|---|---|---|
| `profile` | `Rxn<UserProfile>` | Identité + données physiques de base |
| `userId` | `RxnInt` | ID backend (nécessaire pour tous les appels API) |
| `primaryGoal` | `RxnString` | Objectif : `lose_weight`, `build_muscle`, etc. |
| `targetWeight` | `RxnDouble` | Poids cible |
| `sessionsPerWeek` | `RxnInt` | Séances par semaine |
| `age` | `RxnInt` | Âge |
| `gender` | `RxnString` | Genre |
| `actualWeight` | `RxnDouble` | Poids actuel (mis à jour par pesée, distinct du poids initial) |

### Méthodes

| Méthode | Description |
|---|---|
| `setFromRegistration({name, email, weight?, height?, sportObjective?, targetWeight?, sessionsPerWeek?, age?, gender?})` | Peuple le contrôleur depuis le formulaire d'onboarding. Sauvegarde automatiquement en local. |
| `setFromApiResponse(apiUser)` | Peuple le contrôleur depuis la réponse de `GET /auth/me`. Fusionne avec les données locales existantes. Appeler après `login()`. |
| `clear()` | Réinitialise toutes les données et efface SharedPreferences (à appeler au logout). |

---

## ActiveProgrammeController — `lib/controllers/active_programme_controller.dart`

Contrôleur **local uniquement** (SharedPreferences). Gère le programme de sport actif de l'utilisateur et sa progression séance par séance. Aucun appel réseau.

### Données observables

| Propriété | Type | Contenu |
|---|---|---|
| `activeProgramme` | `Rxn<ActiveProgrammeData>` | Programme en cours (null si aucun) |
| `hasActive` | `bool` | `true` si un programme est en cours |

### Méthodes

| Méthode | Description |
|---|---|
| `demarrer({programmeId, nom, couleurValue, exercices})` | Démarre un nouveau programme et crée la séance 1. Remplace tout programme en cours. |
| `validerSerie(analyzerKey, reps)` | Enregistre une série validée pour un exercice de la séance en cours. Marque automatiquement la séance comme terminée si tous les exercices sont finis. |
| `nouvelleSeance()` | Crée et démarre la séance suivante (n+1). |
| `arreter()` | Abandonne le programme en cours et efface les données locales. |

---

## UserRepository / UserDataSource — `lib/features/user_profile/`

Couche d'accès **direct à PostgreSQL** (connexion via `package:postgres`). Utilisée uniquement dans le contexte Clean Architecture du feature `user_profile`. Pour les autres pages, préférer `AuthService` qui passe par l'API REST.

### UserRepository (interface)

| Méthode | Description |
|---|---|
| `createUser({email, firstName, lastName, weightKg?, heightCm?, sportObjective?, avatarUrl?})` | Insère un nouvel utilisateur. Retourne `UserProfile`. |
| `getUserById(id)` | Récupère un utilisateur par son ID. Retourne `UserProfile?` (null si introuvable). |
| `updateUser(user)` | Met à jour poids, taille, objectif et avatar. Retourne `UserProfile` mis à jour. |
| `deleteUser(id)` | Supprime un utilisateur. Pas de retour. |

### Champs mis à jour par `updateUser`

Seuls ces 4 champs sont modifiables via cette couche :
- `weight_in_kg`
- `height_in_cm`
- `sport_objective`
- `avatar_url`

> `email`, `first_name` et `last_name` ne sont **pas** modifiables via `updateUser`.
> Pour les modifier, utiliser `AuthService.updateUserProfile()` qui passe par l'API.

---

## ApiClient — `lib/services/api_client.dart`

Couche HTTP de bas niveau. **Ne pas l'utiliser directement depuis les pages.** Passe toujours par `AuthService`.

### Ce qu'il gère automatiquement

- Ajout du header `Authorization: Bearer <token>` sur chaque requête
- Timeout de **10 secondes** sur tous les appels
- En cas de **401** : efface le token et redirige vers `LoginPage`
- Décodage UTF-8 des réponses

### Méthodes disponibles (usage interne)

| Méthode | Description |
|---|---|
| `get(path)` | Requête GET |
| `post(path, body)` | Requête POST avec body JSON |
| `put(path, body)` | Requête PUT avec body JSON |
| `delete(path)` | Requête DELETE |
| `isAuthenticated` | `true` si un token est en mémoire |
| `setToken(token)` | Stocke le JWT (appelé par `AuthService.login`) |
| `clearToken()` | Efface le JWT (appelé par `AuthService.logout`) |
