import '../../domain/entities/user.dart';

class UserModel extends User {
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      weightKg: (json['weight_in_kg'] as num?)?.toDouble(),
      heightCm: (json['height_in_cm'] as num?)?.toDouble(),
      sportObjective: json['sport_objective'],
      avatarUrl: json['avatar_url'],
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
