import 'package:hive/hive.dart';

part 'meditation_models.g.dart';

@HiveType(typeId: 2)
class MeditationSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int startTime;

  @HiveField(2)
  final int? endTime;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final String musicTrack;

  MeditationSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.isCompleted,
    required this.musicTrack,
  });

  DateTime get startDateTime => DateTime.fromMillisecondsSinceEpoch(startTime);

  DateTime? get endDateTime =>
      endTime != null ? DateTime.fromMillisecondsSinceEpoch(endTime!) : null;

  Duration get actualDuration {
    final end = endDateTime ?? DateTime.now();
    return end.difference(startDateTime);
  }

  String get dateKey {
    final date = startDateTime;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class MusicTrack {
  final String name;
  final String displayName;
  final String assetPath;

  const MusicTrack({
    required this.name,
    required this.displayName,
    required this.assetPath,
  });
}

// Available music tracks
const List<MusicTrack> availableTracks = [
  MusicTrack(
    name: 'peaceful',
    displayName: 'Peaceful Mind',
    assetPath: 'assets/music/peaceful.mp3',
  ),
  MusicTrack(
    name: 'nature',
    displayName: 'Nature Sounds',
    assetPath: 'assets/music/nature.mp3',
  ),
  MusicTrack(
    name: 'rain',
    displayName: 'Rain & Thunder',
    assetPath: 'assets/music/rain.mp3',
  ),
  MusicTrack(
    name: 'ocean',
    displayName: 'Ocean Waves',
    assetPath: 'assets/music/ocean.mp3',
  ),
  MusicTrack(
    name: 'flute',
    displayName: 'Zen Flute',
    assetPath: 'assets/music/flute.mp3',
  ),
];
