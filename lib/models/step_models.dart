import 'package:hive/hive.dart';

part 'step_models.g.dart';

@HiveType(typeId: 3) // Unique ID for Step Log
class DailyStepLog extends HiveObject {
  @HiveField(0)
  final String dateKey; // Format: yyyy-MM-dd

  @HiveField(1)
  final int steps;

  @HiveField(2)
  final int goal;

  DailyStepLog({
    required this.dateKey,
    required this.steps,
    required this.goal,
  });

  // Estimated metrics based on common averages
  // 1 step ≈ 0.762 meters
  double get distanceKm => (steps * 0.000762);
  // 1 step ≈ 0.04 Calories
  int get calories => (steps * 0.04).round();
}
