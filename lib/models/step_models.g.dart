// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyStepLogAdapter extends TypeAdapter<DailyStepLog> {
  @override
  final int typeId = 3;

  @override
  DailyStepLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStepLog(
      dateKey: fields[0] as String,
      steps: fields[1] as int,
      goal: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStepLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.steps)
      ..writeByte(2)
      ..write(obj.goal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStepLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
