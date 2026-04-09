import 'dart:convert';

import 'package:get/get.dart';
import 'package:mindiff_app/features/user_profile/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contrôleur global pour stocker les infos de l'utilisateur
/// remplies pendant l'onboarding et les rendre accessibles
/// aux différentes pages (profil, métriques, programme, etc.).
class UserProfileController extends GetxController {
  /// Profil de base (identité + données physiques principales)
  final Rxn<UserProfile> profile = Rxn<UserProfile>();

  /// Objectif principal (clé interne: lose_weight, build_muscle, etc.)
  final RxnString primaryGoal = RxnString();

  /// Poids cible souhaité
  final RxnDouble targetWeight = RxnDouble();

  /// Nombre de séances par semaine
  final RxnInt sessionsPerWeek = RxnInt();

  /// Âge et genre, utiles pour adapter certains écrans
  final RxnInt age = RxnInt();
  final RxnString gender = RxnString();

  /// Poids actuel (mis à jour par la balance), distinct du poids initial
  final RxnDouble actualWeight = RxnDouble();

  /// ID serveur (backend), nécessaire pour les appels API authentifiés
  final RxnInt userId = RxnInt();

  static const _storageKey = 'user_profile_v1';

  @override
  void onInit() {
    super.onInit();
    // Charger automatiquement le profil éventuel sauvegardé en local
    _loadFromStorage();
  }

  /// Enregistre toutes les données importantes au moment
  /// où l'onboarding est terminé.
  void setFromRegistration({
    required String name,
    required String email,
    double? weight,
    double? height,
    String? sportObjective,
    double? targetWeight,
    int? sessionsPerWeek,
    int? age,
    String? gender,
  }) {
    // Split très simple "Prénom Nom" -> à raffiner si besoin
    final trimmed = name.trim();
    String firstName = trimmed;
    String lastName = '';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      firstName = parts.first;
      lastName = parts.sublist(1).join(' ');
    }

    profile.value = UserProfile(
      id: 0, // Pas encore branché à la BDD
      email: email,
      firstName: firstName.isEmpty ? 'Utilisateur' : firstName,
      lastName: lastName,
      weightKg: weight,
      heightCm: height,
      sportObjective: sportObjective,
      avatarUrl: null,
      themeMode: MyThemeMode.system,
    );

    primaryGoal.value = sportObjective;
    this.targetWeight.value = targetWeight;
    this.sessionsPerWeek.value = sessionsPerWeek;
    this.age.value = age;
    this.gender.value = gender;

    _saveToStorage();
  }

  /// Peuple le contrôleur depuis la réponse de l'API (GET /auth/me)
  void setFromApiResponse(Map<String, dynamic> apiUser) {
    final id = apiUser['id'] as int? ?? 0;
    final email = apiUser['email'] as String? ?? '';
    final username = apiUser['username'] as String? ?? '';

    userId.value = id;

    // Champs profil depuis le backend
    if (apiUser['gender'] != null) gender.value = apiUser['gender'] as String;
    if (apiUser['sport_objective'] != null) primaryGoal.value = apiUser['sport_objective'] as String;
    if (apiUser['target_weight'] != null) targetWeight.value = (apiUser['target_weight'] as num).toDouble();
    if (apiUser['sessions_per_week'] != null) sessionsPerWeek.value = apiUser['sessions_per_week'] as int;

    // Dernières métriques (poids, taille, âge)
    final metricsList = apiUser['user_metrics'] as List<dynamic>? ?? [];
    double? weight;
    double? height;
    if (metricsList.isNotEmpty) {
      final latest = metricsList.last as Map<String, dynamic>;
      weight = (latest['weight'] as num?)?.toDouble();
      height = (latest['height'] as num?)?.toDouble();
      if (latest['age'] != null) age.value = latest['age'] as int;
      if (latest['actual_weight'] != null) {
        actualWeight.value = (latest['actual_weight'] as num).toDouble();
      }
    }

    // Mettre à jour le profil complet
    profile.value = UserProfile(
      id: id,
      email: email,
      firstName: profile.value?.firstName ?? username,
      lastName: profile.value?.lastName ?? '',
      weightKg: weight ?? profile.value?.weightKg,
      heightCm: height ?? profile.value?.heightCm,
      sportObjective: apiUser['sport_objective'] as String? ?? profile.value?.sportObjective,
      avatarUrl: profile.value?.avatarUrl,
      themeMode: profile.value?.themeMode ?? MyThemeMode.system,
    );

    _saveToStorage();
  }

  /// Réinitialise toutes les données (logout)
  Future<void> clear() async {
    profile.value = null;
    primaryGoal.value = null;
    targetWeight.value = null;
    sessionsPerWeek.value = null;
    age.value = null;
    gender.value = null;
    userId.value = null;
    actualWeight.value = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'profile': profile.value == null
          ? null
          : {
              'id': profile.value!.id,
              'email': profile.value!.email,
              'firstName': profile.value!.firstName,
              'lastName': profile.value!.lastName,
              'weightKg': profile.value!.weightKg,
              'heightCm': profile.value!.heightCm,
              'sportObjective': profile.value!.sportObjective,
              'avatarUrl': profile.value!.avatarUrl,
            },
      'primaryGoal': primaryGoal.value,
      'targetWeight': targetWeight.value,
      'sessionsPerWeek': sessionsPerWeek.value,
      'age': age.value,
      'gender': gender.value,
      'userId': userId.value,
      'actualWeight': actualWeight.value,
    };

    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;

      final profileJson = data['profile'] as Map<String, dynamic>?;
      if (profileJson != null) {
        profile.value = UserProfile(
          id: profileJson['id'] as int? ?? 0,
          email: profileJson['email'] as String? ?? '',
          firstName: profileJson['firstName'] as String? ?? 'Utilisateur',
          lastName: profileJson['lastName'] as String? ?? '',
          weightKg: (profileJson['weightKg'] as num?)?.toDouble(),
          heightCm: (profileJson['heightCm'] as num?)?.toDouble(),
          sportObjective: profileJson['sportObjective'] as String?,
          avatarUrl: profileJson['avatarUrl'] as String?,
          themeMode: MyThemeMode.system,
        );
      }

      primaryGoal.value = data['primaryGoal'] as String?;
      targetWeight.value = (data['targetWeight'] as num?)?.toDouble();
      sessionsPerWeek.value = data['sessionsPerWeek'] as int?;
      age.value = data['age'] as int?;
      gender.value = data['gender'] as String?;
      userId.value = data['userId'] as int?;
      actualWeight.value = (data['actualWeight'] as num?)?.toDouble();
    } catch (_) {
      // En cas de données corrompues, on ignore simplement
    }
  }
}

