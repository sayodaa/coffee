import 'package:coffee_app/features/profile/domain/entities/profile_entity.dart';
import 'package:hive/hive.dart';

part 'profile_model.g.dart';

/// Hive-persisted model for user profile.
/// TypeId 30 — avoids conflicts with existing adapters.
@HiveType(typeId: 30)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String fullName;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String role;

  @HiveField(4)
  final String bio;

  @HiveField(5)
  final String? imagePath;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  ProfileModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.bio,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts this Hive model to an immutable domain entity.
  ProfileEntity toEntity() {
    return ProfileEntity(
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      bio: bio,
      imagePath: imagePath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a Hive model from a domain entity.
  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      role: entity.role,
      bio: entity.bio,
      imagePath: entity.imagePath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
