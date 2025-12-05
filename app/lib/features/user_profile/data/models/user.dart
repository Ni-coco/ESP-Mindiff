class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final double? weightKg;
  final double? heightCm;
  final String? sportObjective;
  final String? avatarUrl;

  User ({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.weightKg,
    this.heightCm,
    required this.sportObjective,
    this.avatarUrl
});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      weightKg: (json['weight_in_kg'] as num?)?.toDouble(),
      heightCm: (json['height_in_cm'] as num?)?.toDouble(),
      sportObjective: json['sport_objective'],
      avatarUrl: json['avatar_url']
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

  User copyWith({
    double? weightKg,
    double? heightCm,
    String? sportObjective,
    String? firstName,
    String? lastName,
    String? avatarUrl,
}) {
    return User(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      sportObjective: sportObjective ?? this.sportObjective,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}