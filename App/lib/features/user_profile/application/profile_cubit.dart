import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/user_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _repository;
  final int _userId;

  ProfileCubit({required UserRepository repository, required int userId})
      : _repository = repository,
        _userId = userId,
        super(const ProfileInitial()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    emit(ProfileLoading(state.profile));
    try {
      final user = await _repository.getUserById(_userId);
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileError(null, "Utilisateur introuvable"));
      }
    } catch (e) {
      emit(ProfileError(state.profile, e.toString()));
    }
  }

  // Fusion de ton toggleTheme et de la persistence
  Future<void> toggleTheme() async {
    if (state is! ProfileLoaded) return;
    
    final currentTheme = state.profile!.themeMode;
    final newTheme = currentTheme == MyThemeMode.light ? MyThemeMode.dark : MyThemeMode.light;
    
    final updated = state.profile!.copyWith(themeMode: newTheme);
    emit(ProfileLoaded(updated)); // Update UI instantané (Optimistic UI)
    
    await _repository.updateUser(updated); // Sauvegarde en BDD
  }

  Future<void> updateDetails({double? weight, double? height, String? objective}) async {
    if (state.profile == null) return;
    
    try {
      final updated = state.profile!.copyWith(
        weightKg: weight,
        heightCm: height,
        sportObjective: objective,
      );
      final savedUser = await _repository.updateUser(updated);
      emit(ProfileLoaded(savedUser));
    } catch (e) {
      emit(ProfileError(state.profile, "Erreur de mise à jour"));
    }
  }
}