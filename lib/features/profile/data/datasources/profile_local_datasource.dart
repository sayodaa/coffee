import 'dart:io';

import 'package:coffee_app/features/profile/data/models/profile_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Handles all Hive read/write and image file operations for Profile.
class ProfileLocalDataSource {
  static const String _boxName = 'profile_box';
  static const String _profileKey = 'user_profile';

  final ImagePicker _imagePicker;

  ProfileLocalDataSource({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  Box<ProfileModel> get _box => Hive.box<ProfileModel>(_boxName);

  /// Reads profile from Hive. Returns null if not found.
  ProfileModel? getProfile() {
    try {
      return _box.get(_profileKey);
    } catch (e) {
      debugPrint('[ProfileLocalDataSource] getProfile error: $e');
      return null;
    }
  }

  /// Saves profile model to Hive.
  Future<void> saveProfile(ProfileModel model) async {
    try {
      await _box.put(_profileKey, model);
    } catch (e) {
      debugPrint('[ProfileLocalDataSource] saveProfile error: $e');
      rethrow;
    }
  }

  /// Deletes profile from Hive.
  Future<void> deleteProfile() async {
    try {
      await _box.delete(_profileKey);
    } catch (e) {
      debugPrint('[ProfileLocalDataSource] deleteProfile error: $e');
      rethrow;
    }
  }

  /// Picks an image from [source], copies it to the permanent app directory,
  /// and returns the absolute path to the copied file.
  ///
  /// Returns `null` if user cancels or permission is denied.
  /// Never stores temporary cache paths.
  Future<String?> pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Copy to permanent app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${appDir.path}/profile_images');
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = pickedFile.path.split('.').last;
      final permanentPath =
          '${profileImagesDir.path}/profile_$timestamp.$extension';

      // Copy from temp to permanent location
      final tempFile = File(pickedFile.path);
      await tempFile.copy(permanentPath);

      return permanentPath;
    } catch (e) {
      debugPrint('[ProfileLocalDataSource] pickAndSaveImage error: $e');
      return null;
    }
  }

  /// Deletes an image file from disk if it exists.
  Future<void> deleteImageFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[ProfileLocalDataSource] deleteImageFile error: $e');
    }
  }
}
