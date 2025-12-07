import 'package:hive/hive.dart';

part 'diet_models.g.dart';

@HiveType(typeId: 0)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String food;

  @HiveField(2)
  final String type; // breakfast, lunch, dinner, snack, water, coffee

  @HiveField(3)
  final int timestamp;

  FoodItem({
    required this.id,
    required this.food,
    required this.type,
    required this.timestamp,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  String get dateKey {
    final date = dateTime;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

@HiveType(typeId: 1)
class FastingSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int startTime;

  @HiveField(2)
  final int? endTime;

  @HiveField(3)
  final int targetHours;

  @HiveField(4)
  final bool isActive;

  FastingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.targetHours,
    required this.isActive,
  });

  DateTime get startDateTime => DateTime.fromMillisecondsSinceEpoch(startTime);

  DateTime? get endDateTime =>
      endTime != null ? DateTime.fromMillisecondsSinceEpoch(endTime!) : null;

  Duration get duration {
    final end = endDateTime ?? DateTime.now();
    return end.difference(startDateTime);
  }

  bool get isCompleted => duration.inHours >= targetHours;

  String get dateKey {
    final date = startDateTime;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
