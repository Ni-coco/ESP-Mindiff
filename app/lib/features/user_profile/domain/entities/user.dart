class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final double? weightKg;
  final double? heightCm;
  final String? sportObjective;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.weightKg,
    this.heightCm,
    this.sportObjective,
    this.avatarUrl,
  });

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
