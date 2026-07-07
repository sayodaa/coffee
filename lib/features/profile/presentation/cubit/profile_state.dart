import 'package:coffee_app/features/profile/domain/entities/profile_entity.dart';
import 'package:equatable/equatable.dart';

/// All possible states for the Profile feature.
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load attempt.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading profile from storage.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile successfully loaded (may be empty if first time).
class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Currently saving profile to storage.
class ProfileSaving extends ProfileState {
  final ProfileEntity profile;

  const ProfileSaving(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Profile saved successfully.
class ProfileSaved extends ProfileState {
  final ProfileEntity profile;

  const ProfileSaved(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Picking an image (camera or gallery).
class ProfileImagePicking extends ProfileState {
  final ProfileEntity profile;

  const ProfileImagePicking(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// An error occurred.
class ProfileError extends ProfileState {
  final String message;
  final ProfileEntity? profile;

  const ProfileError(this.message, {this.profile});

  @override
  List<Object?> get props => [message, profile];
}
