import 'package:postgres/postgres.dart';
import '../models/user_model.dart';
import 'user_datasource.dart';

class UserDataSourceImpl implements UserDataSource {
  final PostgreSQLConnection connection;

  UserDataSourceImpl(this.connection);

  @override
  Future<UserModel> insertUser(UserModel user) async {
    final result = await connection.query('''
      INSERT INTO users (email, first_name, last_name, weight_in_kg, height_in_cm, sport_objective, avatar_url)
      VALUES (@email, @firstName, @lastName, @weight, @height, @objective, @avatar)
      RETURNING id, email, first_name, last_name, weight_in_kg, height_in_cm, sport_objective, avatar_url;
    ''', substitutionValues: {
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'weight': user.weightKg,
      'height': user.heightCm,
      'objective': user.sportObjective,
      'avatar': user.avatarUrl,
    });

    return UserModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<UserModel?> getUserById(int id) async {
    final result = await connection.query(
      'SELECT * FROM users WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (result.isEmpty) return null;

    return UserModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final result = await connection.query('''
      UPDATE users
      SET weight_in_kg = @weight,
          height_in_cm = @height,
          sport_objective = @objective,
          avatar_url = @avatar
      WHERE id = @id
      RETURNING *;
    ''', substitutionValues: {
      'id': user.id,
      'weight': user.weightKg,
      'height': user.heightCm,
      'objective': user.sportObjective,
      'avatar': user.avatarUrl,
    });

    return UserModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<void> deleteUser(int id) async {
    await connection.query('DELETE FROM users WHERE id = @id', substitutionValues: {'id': id});
  }
}
