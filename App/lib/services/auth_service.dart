import 'package:get/get.dart';
import 'api_client.dart';

class AuthService extends GetxService {
  final ApiClient _api = Get.find<ApiClient>();

  /// Dérive un username depuis le nom complet ou l'email
  String _deriveUsername(String name, String email) {
    if (name.trim().isNotEmpty) {
      return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    }
    return email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Inscription → POST /auth/register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String name = '',
  }) async {
    final username = _deriveUsername(name, email);
    final response = await _api.post('/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    });
    return response as Map<String, dynamic>;
  }

  /// Connexion → POST /auth/login → stocke le JWT
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    final token = response['access_token'] as String;
    await _api.setToken(token);
    return response;
  }

  /// Récupère le profil de l'utilisateur connecté → GET /auth/me
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _api.get('/auth/me');
    return response as Map<String, dynamic>;
  }

  /// Met à jour le profil complet → PUT /user/{userId}
  Future<void> updateUserProfile(
    int userId, {
    required String email,
    required String username,
    double? weight,
    int? height,
    int? age,
    String? gender,
    String? sportObjective,
    double? targetWeight,
    int? sessionsPerWeek,
    String? healthConsiderations,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'username': username,
    };

    // Métriques : tous les 3 requis par le backend
    if (weight != null && height != null && age != null) {
      body['metrics'] = {
        'weight': weight,
        'actual_weight': weight, // à l'inscription, poids actuel = poids de départ
        'height': height,
        'age': age,
      };
    }

    if (gender != null) body['gender'] = gender;
    if (sportObjective != null) body['sport_objective'] = sportObjective;
    if (targetWeight != null) body['target_weight'] = targetWeight;
    if (sessionsPerWeek != null) body['sessions_per_week'] = sessionsPerWeek;
    if (healthConsiderations != null && healthConsiderations.isNotEmpty) {
      body['health_considerations'] = healthConsiderations;
    }

    await _api.put('/user/$userId', body);
  }

  Future<void> deleteAccount(int userId) async {
    try {
      // On appelle la route de suppression sur le backend
      await _api.delete('/user/$userId');
      
      // Une fois supprimé en BDD, on nettoie le token localement
      await logout();
    } catch (e) {
      // On propage l'erreur pour pouvoir l'afficher dans l'UI
      rethrow;
    }
  }
  /// Historique de poids → GET /user/{userId}/weight-history
  Future<List<Map<String, dynamic>>> getWeightHistory(int userId) async {
    final response = await _api.get('/user/$userId/weight-history') as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(response['entries'] as List);
  }

  /// Ajouter une pesée → POST /user/{userId}/weight
  Future<void> addWeight(int userId, double weight, {String source = 'manual'}) async {
    await _api.post('/user/$userId/weight', {'weight': weight, 'source': source});
  }

  /// Repas du jour → GET /user/{userId}/meals?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getMeals(int userId, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final response = await _api.get('/user/$userId/meals?date=$dateStr');
    return response as Map<String, dynamic>;
  }

  /// Ajouter un repas → POST /user/{userId}/meals
  Future<Map<String, dynamic>> addMeal(
    int userId, {
    required String mealType,
    required String description,
    DateTime? date,
    double? calories,
    double? proteinG,
    double? fatG,
    double? carbsG,
    double? fiberG,
  }) async {
    final body = <String, dynamic>{
      'meal_type': mealType,
      'description': description,
    };
    if (date != null) {
      body['date'] = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (calories != null) {
      body['calories'] = calories;
      body['protein_g'] = proteinG ?? 0.0;
      body['fat_g'] = fatG ?? 0.0;
      body['carbs_g'] = carbsG ?? 0.0;
      body['fiber_g'] = fiberG ?? 0.0;
    }
    final response = await _api.post('/user/$userId/meals', body);
    return response as Map<String, dynamic>;
  }

  /// Supprimer un repas → DELETE /user/{userId}/meals/{mealId}
  Future<void> deleteMeal(int userId, int mealId) async {
    await _api.delete('/user/$userId/meals/$mealId');
  }

  /// Suggestions de repas journalières → GET /user/{userId}/dashboard/meal-suggestions
  Future<Map<String, dynamic>> getMealSuggestions(int userId) async {
    final response = await _api.get('/user/$userId/dashboard/meal-suggestions');
    return response as Map<String, dynamic>;
  }

  /// Déconnexion → efface le token
  Future<void> logout() async {
    await _api.clearToken();
  }

  // ── Workout ────────────────────────────────────────────────────────────────

  /// Plan de la semaine → GET /user/{id}/workout/current
  Future<Map<String, dynamic>> getCurrentWorkout(int userId) async {
    final response = await _api.get('/user/$userId/workout/current');
    return response as Map<String, dynamic>;
  }

  /// Regénérer le plan → POST /user/{id}/workout/regenerate
  Future<Map<String, dynamic>> regenerateWorkout(int userId) async {
    final response = await _api.post('/user/$userId/workout/regenerate', {});
    return response as Map<String, dynamic>;
  }

  /// Épingler le plan → POST /user/{id}/workout/current/pin
  Future<Map<String, dynamic>> pinWorkout(int userId, int workoutWeekId) async {
    final response = await _api.post(
      '/user/$userId/workout/current/pin?workout_week_id=$workoutWeekId', {},
    );
    return response as Map<String, dynamic>;
  }

  /// Détail d'un exercice → GET /exercise/{id}
  Future<Map<String, dynamic>> getExercise(String exerciseId) async {
    final response = await _api.get('/exercise/${Uri.encodeComponent(exerciseId)}');
    return response as Map<String, dynamic>;
  }

  /// Exercices filtrés → GET /exercise/
  Future<List<dynamic>> getExercises({
    String? target,
    String? bodyPart,
    String? equipment,
    String? q,
    int limit = 50,
  }) async {
    String path;
    if (q != null && q.isNotEmpty) {
      path = '/exercise/filter?q=${Uri.encodeComponent(q)}&limit=$limit';
    } else {
      final params = <String>['limit=$limit'];
      if (target != null) params.add('target=${Uri.encodeComponent(target)}');
      if (bodyPart != null) params.add('body_part=${Uri.encodeComponent(bodyPart)}');
      if (equipment != null) params.add('equipment=${Uri.encodeComponent(equipment)}');
      path = '/exercise/?${params.join('&')}';
    }
    final response = await _api.get(path);
    return response as List<dynamic>;
  }

  /// Créer un workout custom → POST /user/{id}/workout/custom
  Future<Map<String, dynamic>> createCustomWorkout(
    int userId, {
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final response = await _api.post('/user/$userId/workout/custom', {
      'name': name,
      'exercises': exercises,
    });
    return response as Map<String, dynamic>;
  }

  /// Liste workouts custom → GET /user/{id}/workout/custom
  Future<List<dynamic>> getCustomWorkouts(int userId) async {
    final response = await _api.get('/user/$userId/workout/custom');
    return response as List<dynamic>;
  }

  /// Supprimer workout custom → DELETE /user/{id}/workout/custom/{workoutId}
  Future<void> deleteCustomWorkout(int userId, int workoutId) async {
    await _api.delete('/user/$userId/workout/custom/$workoutId');
  }
}
