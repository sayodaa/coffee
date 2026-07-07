import 'package:coffee_app/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:coffee_app/features/profile/data/models/profile_model.dart';
import 'package:coffee_app/features/profile/domain/entities/profile_entity.dart';
import 'package:coffee_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Concrete implementation of [ProfileRepository].
/// Bridges domain → data layer via [ProfileLocalDataSource].
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource _localDataSource;

  const ProfileRepositoryImpl({required ProfileLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<ProfileEntity?> getProfile() async {
    try {
      final model = _localDataSource.getProfile();
      return model?.toEntity();
    } catch (e) {
      debugPrint('[ProfileRepositoryImpl] getProfile error: $e');
      return null;
    }
  }

  @override
  Future<void> saveProfile(ProfileEntity profile) async {
    try {
      final model = ProfileModel.fromEntity(profile);
      await _localDataSource.saveProfile(model);
    } catch (e) {
      debugPrint('[ProfileRepositoryImpl] saveProfile error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProfile() async {
    try {
      await _localDataSource.deleteProfile();
    } catch (e) {
      debugPrint('[ProfileRepositoryImpl] deleteProfile error: $e');
      rethrow;
    }
  }

  @override
  Future<String?> pickAndSaveImage(ImageSource source) async {
    return _localDataSource.pickAndSaveImage(source);
  }

  @override
  Future<void> deleteImageFile(String path) async {
    await _localDataSource.deleteImageFile(path);
  }
}
