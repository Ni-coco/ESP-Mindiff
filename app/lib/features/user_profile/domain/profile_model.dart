// Fichier: lib/features/profile/domain/profile_model.dart

/// Représente le profil de santé de l'utilisateur.
///
/// Ce modèle contient toutes les informations personnelles et de santé
/// stockées dans Firestore. Il est immuable.
class ProfileModel {
  final String userId;
  final String? name; // Nom affiché, peut être null lors de la première connexion
  final int? age;
  final double? weightKg; // Poids en kilogrammes
  final int? heightCm; // Taille en centimètres
  final String? activityLevel; // Ex: 'Sedentary', 'Light', 'Moderate', 'Active'

  // Champs calculés ou par défaut
  final DateTime lastUpdated;

  ProfileModel({
    required this.userId,
    this.name,
    this.age,
    this.weightKg,
    this.heightCm,
    this.activityLevel,
    required this.lastUpdated,
  });

  /// Crée un ProfileModel à partir d'un document Firestore.
  factory ProfileModel.fromFirestore(Map<String, dynamic> data) {
    // Les documents Firestore utilisent 'double' pour les nombres décimaux.
    // L'opérateur 'as' est utilisé pour le casting des types connus.
    return ProfileModel(
      userId: data['userId'] as String,
      name: data['name'] as String?,
      age: data:['age'] as int?,
      weightKg: data['weightKg'] is int ? (data['weightKg'] as int).toDouble() : data['weightKg'] as double?,
      heightCm: data['heightCm'] as int?,
      activityLevel: data['activityLevel'] as String?,
      // Gérer la conversion Timestamp -> DateTime
      lastUpdated: (data['lastUpdated'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertit le ProfileModel en Map pour l'écriture dans Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'activityLevel': activityLevel,
      'lastUpdated': lastUpdated,
    };
  }

  /// Crée une nouvelle instance de ProfileModel avec des champs mis à jour.
  ProfileModel copyWith({
    String? name,
    int? age,
    double? weightKg,
    int? heightCm,
    String? activityLevel,
  }) {
    return ProfileModel(
      userId: this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      lastUpdated: DateTime.now(), // Met à jour le timestamp à chaque modification
    );
  }

  /// Créer un profil initial (pour un nouvel utilisateur).
  factory ProfileModel.initial(String userId) {
    return ProfileModel(
      userId: userId,
      name: 'Nouvel Utilisateur',
      lastUpdated: DateTime.now(),
      activityLevel: 'Sedentary',
    );
  }
}