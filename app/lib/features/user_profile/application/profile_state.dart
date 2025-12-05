import 'package:health_hub/features/profile/domain/user_profile.dart';

/// La classe de base abstraite pour tous les états du Cubit.
/// Elle porte le profil utilisateur, même s'il est incomplet (null) ou en erreur.
abstract class ProfileState {
  final UserProfile? profile;
  const ProfileState(this.profile);
}

/// 1. État initial (avant le chargement des données)
class ProfileInitial extends ProfileState {
  const ProfileInitial() : super(null);
}

/// 2. État de chargement (en attente des données Firestore)
class ProfileLoading extends ProfileState {
  // Le profil peut être non null si on rafraîchit des données existantes (bonne UX)
  const ProfileLoading(super.profile);
}

/// 3. État chargé avec succès (le profil est prêt et complet)
class ProfileLoaded extends ProfileState {
  const ProfileLoaded(UserProfile profile) : super(profile);

  // Getter de commodité pour accéder au profil sans le '?'
  UserProfile get userProfile => profile!;
}

/// 4. État d'erreur (une lecture ou une écriture a échoué)
class ProfileError extends ProfileState {
  final String message;
  const ProfileError(super.profile, this.message);
}