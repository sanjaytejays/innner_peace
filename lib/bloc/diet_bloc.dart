import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../models/diet_models.dart';

// Constants
const String kFoodLogBox = 'food_log_box';
const String kFastingBox = 'fasting_sessions_box';
const String kCurrentFastingBox = 'current_fasting_box';
const int kFastingGoalHours = 16;

// Events
abstract class DietEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDietData extends DietEvent {}

class ToggleFasting extends DietEvent {
  final int targetHours;
  ToggleFasting([this.targetHours = kFastingGoalHours]);
  @override
  List<Object?> get props => [targetHours];
}

class AddFoodItem extends DietEvent {
  final String food;
  final String type;
  AddFoodItem(this.food, this.type);
  @override
  List<Object?> get props => [food, type];
}

class DeleteFoodItem extends DietEvent {
  final String id;
  DeleteFoodItem(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteFastingSession extends DietEvent {
  final String id;
  DeleteFastingSession(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateTimer extends DietEvent {}

// State
class DietState extends Equatable {
  final bool isLoading;
  final FastingSession? activeFasting;
  final List<FoodItem> allFoodLog;
  final List<FastingSession> allFastingSessions;
  final DateTime currentTime;

  const DietState({
    this.isLoading = true,
    this.activeFasting,
    this.allFoodLog = const [],
    this.allFastingSessions = const [],
    required this.currentTime,
  });

  // Get today's food logs
  List<FoodItem> get todayFoodLog {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return allFoodLog.where((item) => item.dateKey == todayKey).toList();
  }

  // Get food logs grouped by date
  Map<String, List<FoodItem>> get foodLogsByDate {
    final Map<String, List<FoodItem>> grouped = {};
    for (var item in allFoodLog) {
      if (!grouped.containsKey(item.dateKey)) {
        grouped[item.dateKey] = [];
      }
      grouped[item.dateKey]!.add(item);
    }
    return grouped;
  }

  // Get fasting sessions grouped by date
  Map<String, List<FastingSession>> get fastingSessionsByDate {
    final Map<String, List<FastingSession>> grouped = {};
    for (var session in allFastingSessions) {
      if (!grouped.containsKey(session.dateKey)) {
        grouped[session.dateKey] = [];
      }
      grouped[session.dateKey]!.add(session);
    }
    return grouped;
  }

  Duration get currentFastingDuration {
    if (activeFasting == null) return Duration.zero;
    return currentTime.difference(activeFasting!.startDateTime);
  }

  double get fastingProgress {
    if (activeFasting == null) return 0.0;
    final minutesPassed = currentFastingDuration.inMinutes;
    final totalMinutes = activeFasting!.targetHours * 60;
    return (minutesPassed / totalMinutes).clamp(0.0, 1.0);
  }

  DietState copyWith({
    bool? isLoading,
    FastingSession? activeFasting,
    List<FoodItem>? allFoodLog,
    List<FastingSession>? allFastingSessions,
    DateTime? currentTime,
    bool clearActiveFasting = false,
  }) {
    return DietState(
      isLoading: isLoading ?? this.isLoading,
      activeFasting: clearActiveFasting
          ? null
          : (activeFasting ?? this.activeFasting),
      allFoodLog: allFoodLog ?? this.allFoodLog,
      allFastingSessions: allFastingSessions ?? this.allFastingSessions,
      currentTime: currentTime ?? this.currentTime,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    activeFasting,
    allFoodLog,
    allFastingSessions,
    currentTime,
  ];
}

// BLoC
class DietBloc extends Bloc<DietEvent, DietState> {
  late Box<FoodItem> foodLogBox;
  late Box<FastingSession> fastingBox;
  late Box currentFastingBox;

  DietBloc() : super(DietState(currentTime: DateTime.now())) {
    on<LoadDietData>(_onLoadDietData);
    on<ToggleFasting>(_onToggleFasting);
    on<AddFoodItem>(_onAddFoodItem);
    on<DeleteFoodItem>(_onDeleteFoodItem);
    on<DeleteFastingSession>(_onDeleteFastingSession);
    on<UpdateTimer>(_onUpdateTimer);
  }

  Future<void> initialize() async {
    foodLogBox = await Hive.openBox<FoodItem>(kFoodLogBox);
    fastingBox = await Hive.openBox<FastingSession>(kFastingBox);
    currentFastingBox = await Hive.openBox(kCurrentFastingBox);
    add(LoadDietData());
  }

  Future<void> _onLoadDietData(
    LoadDietData event,
    Emitter<DietState> emit,
  ) async {
    // Load all food logs
    final allFoodLog = foodLogBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Load all fasting sessions
    final allFastingSessions = fastingBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    // Load active fasting session
    final activeFastingId = currentFastingBox.get('activeFastingId');
    FastingSession? activeFasting;

    if (activeFastingId != null) {
      try {
        activeFasting = allFastingSessions.firstWhere(
          (s) => s.id == activeFastingId && s.isActive,
        );
      } catch (e) {
        // No active fasting session found
        await currentFastingBox.delete('activeFastingId');
      }
    }

    emit(
      state.copyWith(
        isLoading: false,
        activeFasting: activeFasting,
        allFoodLog: allFoodLog,
        allFastingSessions: allFastingSessions,
      ),
    );
  }

  Future<void> _onToggleFasting(
    ToggleFasting event,
    Emitter<DietState> emit,
  ) async {
    if (state.activeFasting != null) {
      // STOP FASTING
      final key = state.activeFasting!.key;
      final endedSession = FastingSession(
        id: state.activeFasting!.id,
        startTime: state.activeFasting!.startTime,
        endTime: DateTime.now().millisecondsSinceEpoch,
        targetHours: state.activeFasting!.targetHours,
        isActive: false,
      );

      await fastingBox.put(key, endedSession);
      await currentFastingBox.delete('activeFastingId');

      final updatedSessions = state.allFastingSessions.map((s) {
        if (s.id == endedSession.id) return endedSession;
        return s;
      }).toList();

      emit(
        state.copyWith(
          clearActiveFasting: true,
          allFastingSessions: updatedSessions,
        ),
      );
    } else {
      // START FASTING
      final now = DateTime.now();
      final newSession = FastingSession(
        id: now.millisecondsSinceEpoch.toString(),
        startTime: now.millisecondsSinceEpoch,
        targetHours: event.targetHours,
        isActive: true,
      );

      await fastingBox.add(newSession);
      await currentFastingBox.put('activeFastingId', newSession.id);

      final updatedSessions = [newSession, ...state.allFastingSessions];

      emit(
        state.copyWith(
          activeFasting: newSession,
          allFastingSessions: updatedSessions,
        ),
      );
    }
  }

  Future<void> _onAddFoodItem(
    AddFoodItem event,
    Emitter<DietState> emit,
  ) async {
    final now = DateTime.now();
    final newItem = FoodItem(
      id: now.millisecondsSinceEpoch.toString(),
      food: event.food,
      type: event.type,
      timestamp: now.millisecondsSinceEpoch,
    );

    await foodLogBox.add(newItem);

    final updatedLog = [newItem, ...state.allFoodLog];
    emit(state.copyWith(allFoodLog: updatedLog));
  }

  Future<void> _onDeleteFoodItem(
    DeleteFoodItem event,
    Emitter<DietState> emit,
  ) async {
    final item = foodLogBox.values.firstWhere((i) => i.id == event.id);
    await item.delete();

    final updatedLog = state.allFoodLog.where((i) => i.id != event.id).toList();
    emit(state.copyWith(allFoodLog: updatedLog));
  }

  Future<void> _onDeleteFastingSession(
    DeleteFastingSession event,
    Emitter<DietState> emit,
  ) async {
    final session = fastingBox.values.firstWhere((s) => s.id == event.id);
    await session.delete();

    final updatedSessions = state.allFastingSessions
        .where((s) => s.id != event.id)
        .toList();
    emit(state.copyWith(allFastingSessions: updatedSessions));
  }

  void _onUpdateTimer(UpdateTimer event, Emitter<DietState> emit) {
    emit(state.copyWith(currentTime: DateTime.now()));
  }
}
