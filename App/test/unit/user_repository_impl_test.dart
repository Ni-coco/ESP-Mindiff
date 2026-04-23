import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindiff_app/features/user_profile/data/datasources/user_datasource.dart';
import 'package:mindiff_app/features/user_profile/data/models/user_model.dart';
import 'package:mindiff_app/features/user_profile/data/repositories/user_repository_impl.dart';
import 'package:mindiff_app/features/user_profile/domain/entities/user.dart';

class MockUserDataSource extends Mock implements UserDataSource {}

const _testModel = UserModel(
  id: 1,
  email: 'test@example.com',
  firstName: 'Alice',
  lastName: 'Dupont',
  weightKg: 65.0,
  heightCm: 170.0,
);

void main() {
  late MockUserDataSource mockDataSource;
  late UserRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const UserModel(
      id: 0,
      email: '',
      firstName: '',
      lastName: '',
    ));
    registerFallbackValue(const UserProfile(
      id: 0,
      email: '',
      firstName: '',
      lastName: '',
    ));
  });

  setUp(() {
    mockDataSource = MockUserDataSource();
    repository = UserRepositoryImpl(mockDataSource);
  });

  group('UserRepositoryImpl.getUserById', () {
    test('retourne un UserProfile quand l\'utilisateur existe', () async {
      when(() => mockDataSource.getUserById(1))
          .thenAnswer((_) async => _testModel);

      final result = await repository.getUserById(1);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.email, 'test@example.com');
      verify(() => mockDataSource.getUserById(1)).called(1);
    });

    test('retourne null quand l\'utilisateur n\'existe pas', () async {
      when(() => mockDataSource.getUserById(99))
          .thenAnswer((_) async => null);

      final result = await repository.getUserById(99);

      expect(result, isNull);
    });
  });

  group('UserRepositoryImpl.createUser', () {
    test('délègue la création au datasource et retourne le profil créé', () async {
      when(() => mockDataSource.insertUser(any()))
          .thenAnswer((_) async => _testModel);

      final result = await repository.createUser(
        email: 'test@example.com',
        firstName: 'Alice',
        lastName: 'Dupont',
        weightKg: 65.0,
        heightCm: 170.0,
      );

      expect(result.email, 'test@example.com');
      expect(result.firstName, 'Alice');
      // L'id 0 est passé à insertUser (la BDD attribuera le vrai id)
      final captured = verify(() => mockDataSource.insertUser(captureAny())).captured;
      expect((captured.first as UserModel).id, 0);
    });
  });

  group('UserRepositoryImpl.updateUser', () {
    test('convertit l\'entité en UserModel avant d\'appeler le datasource', () async {
      const updatedProfile = UserProfile(
        id: 1,
        email: 'test@example.com',
        firstName: 'Alice',
        lastName: 'Dupont',
        weightKg: 60.0,
        heightCm: 168.0,
      );
      const updatedModel = UserModel(
        id: 1,
        email: 'test@example.com',
        firstName: 'Alice',
        lastName: 'Dupont',
        weightKg: 60.0,
        heightCm: 168.0,
      );

      when(() => mockDataSource.updateUser(any()))
          .thenAnswer((_) async => updatedModel);

      final result = await repository.updateUser(updatedProfile);

      expect(result.weightKg, 60.0);
      verify(() => mockDataSource.updateUser(any())).called(1);
    });
  });

  group('UserRepositoryImpl.deleteUser', () {
    test('appelle deleteUser sur le datasource avec le bon id', () async {
      when(() => mockDataSource.deleteUser(1)).thenAnswer((_) async {});

      await repository.deleteUser(1);

      verify(() => mockDataSource.deleteUser(1)).called(1);
    });
  });
}
