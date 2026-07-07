import 'package:equatable/equatable.dart';

/// Domain entity for user profile.
/// Immutable, UI-agnostic, Hive-agnostic.
class ProfileEntity extends Equatable {
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String bio;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.bio,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a default empty profile.
  factory ProfileEntity.empty() {
    final now = DateTime.now();
    return ProfileEntity(
      fullName: '',
      email: '',
      phone: '',
      role: '',
      bio: '',
      imagePath: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  ProfileEntity copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? bio,
    String? Function()? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      imagePath: imagePath != null ? imagePath() : this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasName => fullName.isNotEmpty;

  String get initials {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
        fullName,
        email,
        phone,
        role,
        bio,
        imagePath,
        createdAt,
        updatedAt,
      ];
}
