import 'package:health_hub/features/profile/domain/user_profile.dart';

abstract class ProfileRepository {
  /// Récupère le profil utilisateur par son ID.
  /// Retourne un flux (Stream) pour les mises à jour en temps réel (via onSnapshot de Firestore).
  Stream<UserProfile> getProfile(String userId);

  /// Crée ou met à jour le profil d'un utilisateur.
  Future<void> saveProfile(UserProfile profile);

  /// Enregistre une nouvelle lecture de poids (historique).
  /// Cette méthode sera utilisée par la fonctionnalité Balance Connectée.
  Future<void> addWeightEntry(String userId, double weightKg);
}