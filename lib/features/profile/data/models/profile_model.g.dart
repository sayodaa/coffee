// GENERATED CODE - DO NOT MODIFY BY HAND
// Manual Hive adapter for ProfileModel (typeId: 30)

part of 'profile_model.dart';

class ProfileModelAdapter extends TypeAdapter<ProfileModel> {
  @override
  final int typeId = 30;

  @override
  ProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return ProfileModel(
      fullName: fields[0] as String? ?? '',
      email: fields[1] as String? ?? '',
      phone: fields[2] as String? ?? '',
      role: fields[3] as String? ?? '',
      bio: fields[4] as String? ?? '',
      imagePath: fields[5] as String?,
      createdAt: fields[6] as DateTime? ?? DateTime.now(),
      updatedAt: fields[7] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, ProfileModel obj) {
    writer
      ..writeByte(8) // number of fields
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.bio)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
