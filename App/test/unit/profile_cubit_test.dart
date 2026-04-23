import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindiff_app/features/user_profile/application/profile_cubit.dart';
import 'package:mindiff_app/features/user_profile/application/profile_state.dart';
import 'package:mindiff_app/features/user_profile/domain/entities/user.dart';
import 'package:mindiff_app/features/user_profile/domain/repositories/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository {}

// Constantes de test
const _testUser = UserProfile(
  id: 1,
  email: 'test@example.com',
  firstName: 'Alice',
  lastName: 'Dupont',
  weightKg: 65.0,
  heightCm: 170.0,
  themeMode: MyThemeMode.light,
);

// Comportement bloc_test :
// - ProfileLoading est émis SYNCHRONIQUEMENT dans le constructeur avant que
//   bloc_test attache son listener → jamais capturé.
// - Les états de loadProfile() (ProfileLoaded/ProfileError) sont émis après
//   le premier await getUserById → capturés après un Future.delayed(Duration.zero).
// - Avec act présent : bloc_test appelle act SANS Future.delayed préalable.
//   Il faut donc explicitement `await Future.delayed(Duration.zero)` dans act
//   pour laisser loadProfile() se terminer avant d'invoquer une méthode.

void main() {
  late MockUserRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const UserProfile(
      id: 0,
      email: '',
      firstName: '',
      lastName: '',
    ));
  });

  setUp(() {
    mockRepository = MockUserRepository();
  });

  group('ProfileCubit - loadProfile', () {
    blocTest<ProfileCubit, ProfileState>(
      'émet ProfileLoaded quand l\'utilisateur existe',
      build: () {
        when(() => mockRepository.getUserById(1))
            .thenAnswer((_) async => _testUser);
        return ProfileCubit(repository: mockRepository, userId: 1);
      },
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.userProfile.id,
          'id',
          1,
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'émet ProfileError quand l\'utilisateur est introuvable',
      build: () {
        when(() => mockRepository.getUserById(99))
            .thenAnswer((_) async => null);
        return ProfileCubit(repository: mockRepository, userId: 99);
      },
      expect: () => [
        isA<ProfileError>().having(
          (e) => e.message,
          'message',
          'Utilisateur introuvable',
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'émet ProfileError en cas d\'exception réseau',
      build: () {
        // thenAnswer avec async throw pour garantir un rejet asynchrone du Future
        when(() => mockRepository.getUserById(1))
            .thenAnswer((_) async => throw Exception('Erreur réseau'));
        return ProfileCubit(repository: mockRepository, userId: 1);
      },
      expect: () => [isA<ProfileError>()],
    );
  });

  group('ProfileCubit - toggleTheme', () {
    blocTest<ProfileCubit, ProfileState>(
      'bascule le thème de light à dark',
      build: () {
        when(() => mockRepository.getUserById(1))
            .thenAnswer((_) async => _testUser);
        when(() => mockRepository.updateUser(any()))
            .thenAnswer((inv) async => inv.positionalArguments[0] as UserProfile);
        return ProfileCubit(repository: mockRepository, userId: 1);
      },
      act: (cubit) async {
        await Future.delayed(Duration.zero); // laisse loadProfile émettre ProfileLoaded
        await cubit.toggleTheme();
      },
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.userProfile.themeMode,
          'themeMode initial',
          MyThemeMode.light,
        ),
        isA<ProfileLoaded>().having(
          (s) => s.userProfile.themeMode,
          'themeMode après toggle',
          MyThemeMode.dark,
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'ne fait rien si le profil n\'est pas chargé (ProfileLoading)',
      build: () {
        final completer = Completer<UserProfile?>();
        when(() => mockRepository.getUserById(1))
            .thenAnswer((_) async => completer.future);
        return ProfileCubit(repository: mockRepository, userId: 1);
      },
      act: (cubit) => cubit.toggleTheme(),
      // getUserById ne complète jamais → state reste ProfileLoading → no-op
      expect: () => [],
    );
  });

  group('ProfileCubit - updateDetails', () {
    const updatedUser = UserProfile(
      id: 1,
      email: 'test@example.com',
      firstName: 'Alice',
      lastName: 'Dupont',
      weightKg: 60.0,
      heightCm: 168.0,
      sportObjective: 'endurance',
      themeMode: MyThemeMode.light,
    );

    blocTest<ProfileCubit, ProfileState>(
      'met à jour poids, taille et objectif correctement',
      build: () {
        when(() => mockRepository.getUserById(1))
            .thenAnswer((_) async => _testUser);
        when(() => mockRepository.updateUser(any()))
            .thenAnswer((_) async => updatedUser);
        return ProfileCubit(repository: mockRepository, userId: 1);
      },
      act: (cubit) async {
        await Future.delayed(Duration.zero); // laisse loadProfile émettre ProfileLoaded
        await cubit.updateDetails(
          weight: 60.0,
          height: 168.0,
          objective: 'endurance',
        );
      },
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.userProfile.weightKg,
          'poids initial',
          65.0,
        ),
        isA<ProfileLoaded>().having(
          (s) => s.userProfile.weightKg,
          'poids mis à jour',
          60.0,
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'émet ProfileError si updateUser lève une exception',
      build: () {
        when(() => mockRepository.getUserById(1))
            .thenAnswer((_) async => _testUser);
        when(() => mockRepository.updateUser(any()))
            .thenAnswer((_) async => throw Exception('Erreur serveur'));
        return ProfileCubit(repository: mockRepository, userId: 1);
      },
      act: (cubit) async {
        await Future.delayed(Duration.zero);
        await cubit.updateDetails(weight: 60.0);
      },
      expect: () => [
        isA<ProfileLoaded>(),
        isA<ProfileError>().having(
          (e) => e.message,
          'message',
          'Erreur de mise à jour',
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'ne fait rien si le profil est null (ProfileError après utilisateur introuvable)',
      build: () {
        when(() => mockRepository.getUserById(99))
            .thenAnswer((_) async => null);
        return ProfileCubit(repository: mockRepository, userId: 99);
      },
      act: (cubit) async {
        await Future.delayed(Duration.zero); // laisse loadProfile émettre ProfileError
        await cubit.updateDetails(weight: 60.0);
      },
      // Vérifie qu'exactement 1 état est émis (le ProfileError de loadProfile)
      // et qu'updateDetails n'en émet aucun supplémentaire (profile == null → return early)
      expect: () => [isA<ProfileError>()],
    );
  });
}
