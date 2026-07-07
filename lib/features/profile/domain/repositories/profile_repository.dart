import 'package:coffee_app/features/profile/domain/entities/profile_entity.dart';
import 'package:image_picker/image_picker.dart';

/// Abstract contract for profile data operations.
/// Implementations handle Hive persistence and image file management.
abstract class ProfileRepository {
  /// Loads the saved profile, or `null` if none exists.
  Future<ProfileEntity?> getProfile();

  /// Persists the profile to local storage.
  Future<void> saveProfile(ProfileEntity profile);

  /// Deletes the entire profile record.
  Future<void> deleteProfile();

  /// Picks an image from [source], copies it to the app's permanent
  /// documents directory, and returns the absolute file path.
  /// Returns `null` if the user cancels or permission is denied.
  Future<String?> pickAndSaveImage(ImageSource source);

  /// Deletes the profile image file from disk.
  Future<void> deleteImageFile(String path);
}
