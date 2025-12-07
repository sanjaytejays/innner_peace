import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/meditation_models.dart';

// Constants
const String kMeditationBox = 'meditation_sessions_box';
const String kSettingsBox = 'meditation_settings_box';

// Events
abstract class MeditationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMeditationData extends MeditationEvent {}

class StartMeditation extends MeditationEvent {
  final int durationMinutes;
  StartMeditation(this.durationMinutes);
  @override
  List<Object?> get props => [durationMinutes];
}

class PauseMeditation extends MeditationEvent {}

class ResumeMeditation extends MeditationEvent {}

class StopMeditation extends MeditationEvent {
  final bool completed;
  StopMeditation({this.completed = false});
  @override
  List<Object?> get props => [completed];
}

class UpdateTimer extends MeditationEvent {}

class ChangeMusicTrack extends MeditationEvent {
  final String trackName;
  ChangeMusicTrack(this.trackName);
  @override
  List<Object?> get props => [trackName];
}

class ChangeVolume extends MeditationEvent {
  final double volume;
  ChangeVolume(this.volume);
  @override
  List<Object?> get props => [volume];
}

class DeleteMeditationSession extends MeditationEvent {
  final String id;
  DeleteMeditationSession(this.id);
  @override
  List<Object?> get props => [id];
}

// State
class MeditationState extends Equatable {
  final bool isLoading;
  final MeditationSession? activeSession;
  final List<MeditationSession> allSessions;
  final DateTime currentTime;
  final bool isPaused;
  final int pausedSeconds;
  final String selectedMusicTrack;
  final double volume;

  const MeditationState({
    this.isLoading = true,
    this.activeSession,
    this.allSessions = const [],
    required this.currentTime,
    this.isPaused = false,
    this.pausedSeconds = 0,
    this.selectedMusicTrack = 'peaceful',
    this.volume = 0.5,
  });

  Duration get elapsed {
    if (activeSession == null) return Duration.zero;
    return currentTime.difference(activeSession!.startDateTime) -
        Duration(seconds: pausedSeconds);
  }

  Duration get remaining {
    if (activeSession == null) return Duration.zero;
    final target = Duration(minutes: activeSession!.durationMinutes);
    final remaining = target - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get progress {
    if (activeSession == null) return 0.0;
    final totalSeconds = activeSession!.durationMinutes * 60;
    final elapsedSeconds = elapsed.inSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  bool get isCompleted => remaining == Duration.zero && activeSession != null;

  Map<String, List<MeditationSession>> get sessionsByDate {
    final Map<String, List<MeditationSession>> grouped = {};
    for (var session in allSessions) {
      if (!grouped.containsKey(session.dateKey)) {
        grouped[session.dateKey] = [];
      }
      grouped[session.dateKey]!.add(session);
    }
    return grouped;
  }

  MeditationState copyWith({
    bool? isLoading,
    MeditationSession? activeSession,
    List<MeditationSession>? allSessions,
    DateTime? currentTime,
    bool? isPaused,
    int? pausedSeconds,
    String? selectedMusicTrack,
    double? volume,
    bool clearActiveSession = false,
  }) {
    return MeditationState(
      isLoading: isLoading ?? this.isLoading,
      activeSession: clearActiveSession
          ? null
          : (activeSession ?? this.activeSession),
      allSessions: allSessions ?? this.allSessions,
      currentTime: currentTime ?? this.currentTime,
      isPaused: isPaused ?? this.isPaused,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      selectedMusicTrack: selectedMusicTrack ?? this.selectedMusicTrack,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    activeSession,
    allSessions,
    currentTime,
    isPaused,
    pausedSeconds,
    selectedMusicTrack,
    volume,
  ];
}

// BLoC
class MeditationBloc extends Bloc<MeditationEvent, MeditationState> {
  late Box<MeditationSession> meditationBox;
  late Box settingsBox;
  final AudioPlayer audioPlayer = AudioPlayer();
  DateTime? pauseStartTime;

  MeditationBloc() : super(MeditationState(currentTime: DateTime.now())) {
    on<LoadMeditationData>(_onLoadMeditationData);
    on<StartMeditation>(_onStartMeditation);
    on<PauseMeditation>(_onPauseMeditation);
    on<ResumeMeditation>(_onResumeMeditation);
    on<StopMeditation>(_onStopMeditation);
    on<UpdateTimer>(_onUpdateTimer);
    on<ChangeMusicTrack>(_onChangeMusicTrack);
    on<ChangeVolume>(_onChangeVolume);
    on<DeleteMeditationSession>(_onDeleteMeditationSession);
  }

  Future<void> initialize() async {
    meditationBox = await Hive.openBox<MeditationSession>(kMeditationBox);
    settingsBox = await Hive.openBox(kSettingsBox);

    // Set audio player to loop
    audioPlayer.setReleaseMode(ReleaseMode.loop);

    add(LoadMeditationData());
  }

  Future<void> _onLoadMeditationData(
    LoadMeditationData event,
    Emitter<MeditationState> emit,
  ) async {
    final allSessions = meditationBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final selectedTrack = settingsBox.get(
      'selectedMusicTrack',
      defaultValue: 'peaceful',
    );
    final volume = settingsBox.get('volume', defaultValue: 0.5);

    emit(
      state.copyWith(
        isLoading: false,
        allSessions: allSessions,
        selectedMusicTrack: selectedTrack,
        volume: volume,
      ),
    );
  }

  Future<void> _onStartMeditation(
    StartMeditation event,
    Emitter<MeditationState> emit,
  ) async {
    final now = DateTime.now();
    final session = MeditationSession(
      id: now.millisecondsSinceEpoch.toString(),
      startTime: now.millisecondsSinceEpoch,
      durationMinutes: event.durationMinutes,
      isCompleted: false,
      musicTrack: state.selectedMusicTrack,
    );

    await meditationBox.add(session);

    // Play music
    final track = availableTracks.firstWhere(
      (t) => t.name == state.selectedMusicTrack,
      orElse: () => availableTracks.first,
    );

    await audioPlayer.setVolume(state.volume);
    await audioPlayer.play(
      AssetSource(track.assetPath.replaceFirst('assets/', '')),
    );

    final updatedSessions = [session, ...state.allSessions];

    emit(
      state.copyWith(
        activeSession: session,
        allSessions: updatedSessions,
        isPaused: false,
        pausedSeconds: 0,
      ),
    );
  }

  Future<void> _onPauseMeditation(
    PauseMeditation event,
    Emitter<MeditationState> emit,
  ) async {
    await audioPlayer.pause();
    pauseStartTime = DateTime.now();
    emit(state.copyWith(isPaused: true));
  }

  Future<void> _onResumeMeditation(
    ResumeMeditation event,
    Emitter<MeditationState> emit,
  ) async {
    await audioPlayer.resume();

    if (pauseStartTime != null) {
      final pauseDuration = DateTime.now().difference(pauseStartTime!);
      final totalPausedSeconds = state.pausedSeconds + pauseDuration.inSeconds;
      emit(state.copyWith(isPaused: false, pausedSeconds: totalPausedSeconds));
    } else {
      emit(state.copyWith(isPaused: false));
    }

    pauseStartTime = null;
  }

  Future<void> _onStopMeditation(
    StopMeditation event,
    Emitter<MeditationState> emit,
  ) async {
    await audioPlayer.stop();

    if (state.activeSession != null) {
      final key = state.activeSession!.key;
      final endedSession = MeditationSession(
        id: state.activeSession!.id,
        startTime: state.activeSession!.startTime,
        endTime: DateTime.now().millisecondsSinceEpoch,
        durationMinutes: state.activeSession!.durationMinutes,
        isCompleted: event.completed,
        musicTrack: state.activeSession!.musicTrack,
      );

      await meditationBox.put(key, endedSession);

      final updatedSessions = state.allSessions.map((s) {
        if (s.id == endedSession.id) return endedSession;
        return s;
      }).toList();

      emit(
        state.copyWith(
          clearActiveSession: true,
          allSessions: updatedSessions,
          isPaused: false,
          pausedSeconds: 0,
        ),
      );
    }

    pauseStartTime = null;
  }

  void _onUpdateTimer(UpdateTimer event, Emitter<MeditationState> emit) {
    if (state.activeSession != null && !state.isPaused) {
      final newState = state.copyWith(currentTime: DateTime.now());

      // Auto-complete when time is up
      if (newState.isCompleted && !state.isCompleted) {
        add(StopMeditation(completed: true));
      } else {
        emit(newState);
      }
    }
  }

  Future<void> _onChangeMusicTrack(
    ChangeMusicTrack event,
    Emitter<MeditationState> emit,
  ) async {
    await settingsBox.put('selectedMusicTrack', event.trackName);
    emit(state.copyWith(selectedMusicTrack: event.trackName));

    // If music is playing, switch tracks
    if (state.activeSession != null && !state.isPaused) {
      final track = availableTracks.firstWhere(
        (t) => t.name == event.trackName,
        orElse: () => availableTracks.first,
      );
      await audioPlayer.stop();
      await audioPlayer.play(
        AssetSource(track.assetPath.replaceFirst('assets/', '')),
      );
    }
  }

  Future<void> _onChangeVolume(
    ChangeVolume event,
    Emitter<MeditationState> emit,
  ) async {
    await settingsBox.put('volume', event.volume);
    await audioPlayer.setVolume(event.volume);
    emit(state.copyWith(volume: event.volume));
  }

  Future<void> _onDeleteMeditationSession(
    DeleteMeditationSession event,
    Emitter<MeditationState> emit,
  ) async {
    final session = meditationBox.values.firstWhere((s) => s.id == event.id);
    await session.delete();

    final updatedSessions = state.allSessions
        .where((s) => s.id != event.id)
        .toList();
    emit(state.copyWith(allSessions: updatedSessions));
  }

  @override
  Future<void> close() {
    audioPlayer.dispose();
    return super.close();
  }
}
