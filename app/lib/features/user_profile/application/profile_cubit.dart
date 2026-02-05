import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindiff_app/features/user_profile/application/profile_state.dart';
import 'package:mindiff_app/features/user_profile/domain/repositories/user_repository.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _profileRepository;
  final int _currentUserId; // Changé de String à int pour correspondre à UserProfile

  ProfileCubit({
    required UserRepository profileRepository,
    required int currentUserId, // Changé ici aussi
  }) : _profileRepository = profileRepository,
        _currentUserId = currentUserId,
        super(const ProfileInitial()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    emit(const ProfileLoading(null));

    try {
      // Puisque getUserById est une Future (d'après ton UserRepositoryImpl)
      final profile = await _profileRepository.getUserById(_currentUserId);
      
      if (profile != null) {
        emit(ProfileLoaded(profile));
      } else {
        emit(ProfileError(null, "Utilisateur non trouvé"));
      }
    } catch (error) {
      emit(ProfileError(state.profile, "Échec du chargement du profil: $error"));
    }
  }

  Future<void> saveProfileDetails({
    double? heightCm,
    String? sportObjective,
  }) async {
    if (state.profile == null) return;

    try {
      final updatedProfile = state.profile!.copyWith(
        heightCm: heightCm,
        sportObjective: sportObjective,
      );

      // Vérifie que cette méthode existe bien dans ton UserRepository
      // Si elle s'appelle updateUser dans ton Repository, change le nom ici :
      await _profileRepository.updateUser(updatedProfile);

      // Comme on n'est pas en Stream, on émet manuellement le nouvel état
      emit(ProfileLoaded(updatedProfile));

    } catch (e) {
      emit(ProfileError(state.profile, "Échec de l'enregistrement: $e"));
    }
  }

  // Suppression de close() car sans StreamSubscription, le super.close() suffit.
}