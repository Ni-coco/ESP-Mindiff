import '../entities/user.dart';

abstract class UserRepository {
  /// Créer un nouvel utilisateur dans la base
  Future<UserProfile> createUser({
    required String email,
    required String firstName,
    required String lastName,
    double? weightKg,
    double? heightCm,
    String? sportObjective,
    String? avatarUrl,
  });

  /// Récupère un utilisateur par son ID
  Future<UserProfile?> getUserById(int id);

  /// Met à jour un utilisateur
  Future<UserProfile> updateUser(UserProfile user);

  /// Supprime un utilisateur
  Future<void> deleteUser(int id);
}
