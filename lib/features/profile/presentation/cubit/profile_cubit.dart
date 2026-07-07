import 'package:coffee_app/features/profile/domain/entities/profile_entity.dart';
import 'package:coffee_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Manages all profile operations.
/// UI-agnostic — no Flutter widgets or BuildContext.
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial());

  /// Helper to read current profile from state if available.
  ProfileEntity? get _currentProfile {
    final s = state;
    if (s is ProfileLoaded) return s.profile;
    if (s is ProfileSaving) return s.profile;
    if (s is ProfileSaved) return s.profile;
    if (s is ProfileImagePicking) return s.profile;
    if (s is ProfileError) return s.profile;
    return null;
  }

  /// Loads profile from Hive on app start.
  Future<void> loadProfile() async {
    emit(const ProfileLoading());
    try {
      final profile = await _repository.getProfile();
      emit(ProfileLoaded(profile ?? ProfileEntity.empty()));
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  /// Saves / updates profile data.
  Future<void> saveProfile(ProfileEntity profile) async {
    emit(ProfileSaving(profile));
    try {
      final updated = profile.copyWith(updatedAt: DateTime.now());
      await _repository.saveProfile(updated);
      emit(ProfileSaved(updated));
      // Immediately transition to loaded so all listeners update
      emit(ProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError('Failed to save profile: $e', profile: profile));
    }
  }

  /// Picks an image from camera or gallery, copies to permanent storage,
  /// and updates the profile entity.
  Future<void> pickImage(ImageSource source) async {
    final current = _currentProfile ?? ProfileEntity.empty();
    emit(ProfileImagePicking(current));
    try {
      final path = await _repository.pickAndSaveImage(source);
      if (path == null) {
        // User cancelled — go back to loaded
        emit(ProfileLoaded(current));
        return;
      }

      // Delete old image if exists
      if (current.hasImage) {
        await _repository.deleteImageFile(current.imagePath!);
      }

      final updated = current.copyWith(
        imagePath: () => path,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProfile(updated);
      emit(ProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError('Failed to pick image: $e', profile: current));
    }
  }

  /// Removes profile image (deletes file on disk, clears path in Hive).
  Future<void> removeImage() async {
    final current = _currentProfile;
    if (current == null) return;

    try {
      if (current.hasImage) {
        await _repository.deleteImageFile(current.imagePath!);
      }

      final updated = current.copyWith(
        imagePath: () => null,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProfile(updated);
      emit(ProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError('Failed to remove image: $e', profile: current));
    }
  }

  /// Deletes all profile data.
  Future<void> deleteProfile() async {
    try {
      final current = _currentProfile;
      if (current != null && current.hasImage) {
        await _repository.deleteImageFile(current.imagePath!);
      }
      await _repository.deleteProfile();
      emit(ProfileLoaded(ProfileEntity.empty()));
    } catch (e) {
      emit(ProfileError('Failed to delete profile: $e'));
    }
  }
}
