import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/step_models.dart';

// --- CONSTANTS ---
const String kStepHistoryBox = 'step_history_box';
const String kStepPrefsBox = 'step_prefs_box';
const int kDefaultDailyGoal = 10000;

// --- EVENTS ---
abstract class StepEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitStepTracker extends StepEvent {}

class StepCountReceived extends StepEvent {
  final int sensorSteps;
  StepCountReceived(this.sensorSteps);
  @override
  List<Object?> get props => [sensorSteps];
}

// --- STATE (Renamed to avoid conflict) ---
enum StepStatus { initial, loading, active, denied, error }

class StepTrackerState extends Equatable {
  final StepStatus status;
  final int todaySteps;
  final int dailyGoal;
  final List<DailyStepLog> history;
  final String? errorMessage;

  const StepTrackerState({
    this.status = StepStatus.initial,
    this.todaySteps = 0,
    this.dailyGoal = kDefaultDailyGoal,
    this.history = const [],
    this.errorMessage,
  });

  double get progress => (todaySteps / dailyGoal).clamp(0.0, 1.0);

  String get distanceKm => (todaySteps * 0.000762).toStringAsFixed(2);
  String get caloriesBurned => (todaySteps * 0.04).toStringAsFixed(0);

  StepTrackerState copyWith({
    StepStatus? status,
    int? todaySteps,
    int? dailyGoal,
    List<DailyStepLog>? history,
    String? errorMessage,
  }) {
    return StepTrackerState(
      status: status ?? this.status,
      todaySteps: todaySteps ?? this.todaySteps,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    todaySteps,
    dailyGoal,
    history,
    errorMessage,
  ];
}

// --- BLOC ---
class StepBloc extends Bloc<StepEvent, StepTrackerState> {
  late Box<DailyStepLog> _historyBox;
  late Box _prefsBox;
  StreamSubscription<StepCount>? _subscription;

  // Initialize with StepTrackerState
  StepBloc() : super(const StepTrackerState()) {
    on<InitStepTracker>(_onInit);
    on<StepCountReceived>(_onStepCountReceived);
  }

  Future<void> initialize() async {
    add(InitStepTracker());
  }

  Future<void> _onInit(
    InitStepTracker event,
    Emitter<StepTrackerState> emit,
  ) async {
    emit(state.copyWith(status: StepStatus.loading));

    try {
      _historyBox = await Hive.openBox<DailyStepLog>(kStepHistoryBox);
      _prefsBox = await Hive.openBox(kStepPrefsBox);

      _loadHistory(emit);

      final permStatus = await Permission.activityRecognition.request();

      if (permStatus.isGranted) {
        _startListening();
        emit(state.copyWith(status: StepStatus.active));
      } else {
        emit(
          state.copyWith(
            status: StepStatus.denied,
            errorMessage: 'Permission required for step counting.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: StepStatus.error,
          errorMessage: 'Initialization failed: ${e.toString()}',
        ),
      );
    }
  }

  void _startListening() {
    _subscription = Pedometer.stepCountStream.listen(
      (StepCount event) => add(StepCountReceived(event.steps)),
      onError: (error) => print("Pedometer Error: $error"),
    );
  }

  void _onStepCountReceived(
    StepCountReceived event,
    Emitter<StepTrackerState> emit,
  ) {
    final int sensorSteps = event.sensorSteps;
    final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? lastDate = _prefsBox.get('last_record_date');
    int? dayOffset = _prefsBox.get('day_offset');

    int calculatedTodaySteps = 0;

    if (lastDate != todayKey) {
      final yesterdaySteps = _prefsBox.get('temp_steps_today', defaultValue: 0);
      if (lastDate != null && yesterdaySteps > 0) {
        _saveToHistory(lastDate, yesterdaySteps);
      }
      dayOffset = sensorSteps;
      _prefsBox.put('day_offset', dayOffset);
      _prefsBox.put('last_record_date', todayKey);
      calculatedTodaySteps = 0;
    } else {
      if (dayOffset == null) {
        dayOffset = sensorSteps;
        _prefsBox.put('day_offset', dayOffset);
      }
      calculatedTodaySteps = sensorSteps - dayOffset;
      if (calculatedTodaySteps < 0) calculatedTodaySteps = 0;
    }

    _prefsBox.put('temp_steps_today', calculatedTodaySteps);

    emit(
      state.copyWith(
        todaySteps: calculatedTodaySteps,
        status: StepStatus.active,
      ),
    );

    if (lastDate != todayKey && lastDate != null) {
      _loadHistory(emit);
    }
  }

  void _saveToHistory(String dateKey, int steps) {
    final log = DailyStepLog(
      dateKey: dateKey,
      steps: steps,
      goal: state.dailyGoal,
    );
    _historyBox.put(dateKey, log);
  }

  void _loadHistory(Emitter<StepTrackerState> emit) {
    final historyList = _historyBox.values.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));

    emit(state.copyWith(history: historyList));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
