import 'package:postgres/postgres.dart';
import '../models/user_model.dart';
import 'user_datasource.dart';

class UserDataSourceImpl implements UserDataSource {
  // 1. PostgreSQLConnection devient Connection
  final Connection connection;

  UserDataSourceImpl(this.connection);

  @override
  Future<UserModel> insertUser(UserModel user) async {
    // 2. Utilisation de execute() avec la syntaxe de variables $1, $2...
    // Ou l'utilisation de Sql.named() pour garder des noms
    final result = await connection.execute(
      Sql.named('''
        INSERT INTO users (email, first_name, last_name, weight_in_kg, height_in_cm, sport_objective, avatar_url)
        VALUES (@email, @firstName, @lastName, @weight, @height, @objective, @avatar)
        RETURNING id, email, first_name, last_name, weight_in_kg, height_in_cm, sport_objective, avatar_url
      '''),
      parameters: {
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'weight': user.weightKg,
        'height': user.heightCm,
        'objective': user.sportObjective,
        'avatar': user.avatarUrl,
      },
    );

    // 3. Le résultat se lit différemment (result.first est une Row)
    return UserModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<UserModel?> getUserById(int id) async {
    final result = await connection.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;

    return UserModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final result = await connection.execute(
      Sql.named('''
        UPDATE users
        SET weight_in_kg = @weight,
            height_in_cm = @height,
            sport_objective = @objective,
            avatar_url = @avatar
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': user.id,
        'weight': user.weightKg,
        'height': user.heightCm,
        'objective': user.sportObjective,
        'avatar': user.avatarUrl,
      },
    );

    return UserModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<void> deleteUser(int id) async {
    await connection.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
  }
}