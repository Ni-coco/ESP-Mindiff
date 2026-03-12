import '../models/user_model.dart';

abstract class UserDataSource {
  Future<UserModel> insertUser(UserModel user);
  Future<UserModel?> getUserById(int id);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(int id);
}
