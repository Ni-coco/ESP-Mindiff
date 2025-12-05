class UserProfile {
  final String userId;
  final String email;
  final double? heightCm; // Taille en centimètres
  final double? weightKg; // Poids actuel en kilogrammes
  final String? sportObjective; // Objectif sportif (ex: "Perte de poids", "Prise de muscle")

  UserProfile({
    required this.userId,
    required this.email,
    this.heightCm,
    this.weightKg,
    required this.sportObjective,
  });

  /// Crée une nouvelle instance de UserProfile avec des valeurs mises à jour.
  UserProfile copyWith({
    double? heightCm,
    double? weightKg,
    String? sportObjective,
  }) {
    return UserProfile(
      userId: userId,
      email: email,
      // Utilise la nouvelle valeur si fournie, sinon garde l'ancienne
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      sportObjective: sportObjective ?? this.sportObjective,
    );
  }

  /// Convertit le modèle en un format Map pour l'enregistrement dans Firestore.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'sportObjective': sportObjective,
      'updatedAt': DateTime.now().toIso8601String(), // Ajout d'un timestamp de mise à jour
    };
  }

  /// Crée un modèle à partir d'un document Firestore.
  /// Note: Les valeurs 'num?' permettent de gérer à la fois les entiers et les doubles de Firestore.
  factory UserProfile.fromMap(String userId, Map<String, dynamic> map) {
    return UserProfile(
      userId: userId,
      email: map['email'] as String,
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      sportObjective: map['sportObjective'] as String?,
    );
  }
}