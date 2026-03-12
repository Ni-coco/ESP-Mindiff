import '../../domain/entities/user.dart'; // Assure-toi que le chemin est bon

class UserModel extends UserProfile {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.weightKg,
    super.heightCm,
    super.sportObjective,
    super.avatarUrl,
  });

  // Cette méthode permet de transformer une entité en modèle pour la BDD
  factory UserModel.fromEntity(UserProfile entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      firstName: entity.firstName,
      lastName: entity.lastName,
      weightKg: entity.weightKg,
      heightCm: entity.heightCm,
      sportObjective: entity.sportObjective,
      avatarUrl: entity.avatarUrl,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      weightKg: (json['weight_in_kg'] as num?)?.toDouble(),
      heightCm: (json['height_in_cm'] as num?)?.toDouble(),
      sportObjective: json['sport_objective'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'weight_in_kg': weightKg,
      'height_in_cm': heightCm,
      'sport_objective': sportObjective,
      'avatar_url': avatarUrl,
    };
  }
}