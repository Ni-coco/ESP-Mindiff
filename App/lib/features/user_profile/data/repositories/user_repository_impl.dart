import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<UserProfile> createUser({
    required String email,
    required String firstName,
    required String lastName,
    double? weightKg,
    double? heightCm,
    String? sportObjective,
    String? avatarUrl,
  }) async {
    final model = UserModel(
      id: 0,
      email: email,
      firstName: firstName,
      lastName: lastName,
      weightKg: weightKg,
      heightCm: heightCm,
      sportObjective: sportObjective,
      avatarUrl: avatarUrl,
    );

    return await dataSource.insertUser(model);
  }

  @override
  Future<UserProfile?> getUserById(int id) async {
    return await dataSource.getUserById(id);
  }

  @override
  Future<UserProfile> updateUser(UserProfile user) async {
    return await dataSource.updateUser(UserModel.fromEntity(user));
  }

  @override
  Future<void> deleteUser(int id) async {
    await dataSource.deleteUser(id);
  }
}
