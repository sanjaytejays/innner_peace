// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meditation_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeditationSessionAdapter extends TypeAdapter<MeditationSession> {
  @override
  final int typeId = 2;

  @override
  MeditationSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeditationSession(
      id: fields[0] as String,
      startTime: fields[1] as int,
      endTime: fields[2] as int?,
      durationMinutes: fields[3] as int,
      isCompleted: fields[4] as bool,
      musicTrack: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MeditationSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.musicTrack);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeditationSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
