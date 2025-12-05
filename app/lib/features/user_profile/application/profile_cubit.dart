import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_hub/features/profile/application/profile_state.dart';
import 'package:health_hub/features/profile/domain/profile_repository.dart';
import 'package:health_hub/features/profile/domain/user_profile.dart';

/// Un Cubit pour gérer l'état du profil utilisateur.
/// Il dépend du ProfileRepository (couche Domain).
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  final String _currentUserId;
  // Nous utilisons un StreamSubscription pour écouter les mises à jour en temps réel de Firestore.
  StreamSubscription? _profileSubscription;

  ProfileCubit({
    required ProfileRepository profileRepository,
    required String currentUserId,
  }) : _profileRepository = profileRepository,
        _currentUserId = currentUserId,
  // L'état initial est toujours ProfileInitial
        super(const ProfileInitial()) {
    // Démarre l'écoute du profil dès l'initialisation du Cubit
    _loadProfile();
  }

  /// Lance l'écoute du profil utilisateur en temps réel via le Repository.
  void _loadProfile() {
    // Émet l'état de chargement
    emit(const ProfileLoading(null));

    // Lance l'écoute du Repository (qui utilise onSnapshot de Firestore)
    // S'assure d'annuler toute écoute précédente avant de commencer une nouvelle
    _profileSubscription?.cancel();

    _profileSubscription = _profileRepository.getProfile(_currentUserId).listen(
          (profile) {
        // Nouvelle donnée reçue: on passe à l'état Loaded
        emit(ProfileLoaded(profile));
      },
      onError: (error) {
        // Erreur de lecture du stream
        emit(ProfileError(state.profile, "Échec du chargement du profil: $error"));
      },
    );
  }

  /// Sauvegarde les informations du profil (taille et objectif).
  Future<void> saveProfileDetails({
    double? heightCm,
    String? sportObjective,
  }) async {
    // Si l'état actuel est null (initial/erreur sans profil), on ne fait rien.
    if (state.profile == null) return;

    try {
      // 1. Créer une copie du profil avec les nouvelles données
      final updatedProfile = state.profile!.copyWith(
        heightCm: heightCm,
        sportObjective: sportObjective,
      );

      // 2. Appel au Repository (couche Domain) pour effectuer la sauvegarde
      await _profileRepository.saveProfile(updatedProfile);

      // IMPORTANT: Nous n'émettons pas ProfileLoaded ici.
      // Le changement est fait dans Firestore, ce qui déclenchera le stream
      // de '_loadProfile' et mettra à jour l'état automatiquement.

    } catch (e) {
      // Si la sauvegarde échoue, on affiche une erreur
      emit(ProfileError(state.profile, "Échec de l'enregistrement des détails: $e"));
    }
  }

  /// S'assure d'annuler le StreamSubscription pour éviter les fuites de mémoire.
  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}