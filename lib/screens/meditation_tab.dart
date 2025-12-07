import 'dart:async';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/meditation_bloc.dart';
import '../models/meditation_models.dart';

// --- THEME CONSTANTS ---
class AppColors {
  static const bgTop = Color(0xFF1A1F38);
  static const bgBottom = Color(0xFF101426);
  static const accent = Color(0xFFB589D6); // Soft Purple
  static const accentGlow = Color(0xFF9969C7);
  static const cardBg = Color(0xFF232946);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white54;
}

class MeditationTabWidget extends StatefulWidget {
  const MeditationTabWidget({super.key});

  @override
  State<MeditationTabWidget> createState() => _MeditationTabState();
}

// FIX: Changed to TickerProviderStateMixin to allow multiple animations
class _MeditationTabState extends State<MeditationTabWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _breatheController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Slower, more relaxing breathing duration (6 seconds)
    _breatheController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    // Timer logic: Only ticks if mounted.
    // Ideally, this logic should move to the Bloc, but we keep it here to match your architecture.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        // You might want to check if state.isPaused is false before adding the event
        // to reduce unnecessary events, but that depends on your Bloc logic.
        context.read<MeditationBloc>().add(UpdateTimer());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breatheController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<MeditationBloc, MeditationState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              return Column(
                children: [
                  _buildCustomAppBar(context),
                  const SizedBox(height: 10),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildMeditateTab(state),
                        _buildHistoryTab(state),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Inner Peace',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          _GlassIconButton(
            icon: Icons.tune_rounded,
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Session'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildMeditateTab(MeditationState state) {
    if (state.activeSession != null) {
      return _buildActiveSessionView(state);
    }
    return _buildSessionSelector();
  }

  // 1. ACTIVE SESSION VIEW
  Widget _buildActiveSessionView(MeditationState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Breathing Circle Animation
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _breatheController,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withOpacity(
                          0.2 - (_breatheController.value * 0.1),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _breatheController,
              builder: (context, child) {
                return Container(
                  width: 200 + (_breatheController.value * 20),
                  height: 200 + (_breatheController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGlow.withOpacity(0.3),
                        blurRadius: 20 + (_breatheController.value * 10),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(state.remaining),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  state.isPaused ? 'PAUSED' : 'BREATHE',
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 3,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GlassIconButton(
              icon: Icons.stop_rounded,
              color: Colors.redAccent.withOpacity(0.8),
              size: 60,
              iconSize: 30,
              onPressed: () =>
                  context.read<MeditationBloc>().add(StopMeditation()),
            ),
            const SizedBox(width: 30),
            _GlassIconButton(
              icon: state.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              color: AppColors.accent,
              size: 80,
              iconSize: 40,
              isGlowing: true,
              onPressed: () {
                if (state.isPaused) {
                  context.read<MeditationBloc>().add(ResumeMeditation());
                } else {
                  context.read<MeditationBloc>().add(PauseMeditation());
                }
              },
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  // 2. SESSION SELECTION VIEW
  Widget _buildSessionSelector() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Choose Duration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDurationCard(
          5,
          'Quick Reset',
          'Great for a short break',
          Icons.bolt,
        ),
        _buildDurationCard(
          10,
          'Mindfulness',
          'Standard daily practice',
          Icons.water_drop,
        ),
        _buildDurationCard(
          20,
          'Deep Focus',
          'Achieve flow state',
          Icons.psychology,
        ),
        _buildDurationCard(45, 'Sleep', 'Prepare for rest', Icons.bedtime),
      ],
    );
  }

  Widget _buildDurationCard(
    int minutes,
    String title,
    String sub,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.read<MeditationBloc>().add(StartMeditation(minutes)),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: AppColors.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${minutes}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. HISTORY TAB
  Widget _buildHistoryTab(MeditationState state) {
    final sessionsByDate = state.sessionsByDate;
    final dates = sessionsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 64,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              'No sessions yet',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dateKey = dates[index];
        final date = DateTime.parse(dateKey);
        final sessions = sessionsByDate[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                DateFormat('MMMM d, y').format(date).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...sessions.map((session) => _buildHistoryItem(session)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(MeditationSession session) {
    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.2),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        context.read<MeditationBloc>().add(DeleteMeditationSession(session.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              session.isCompleted
                  ? Icons.check_circle
                  : Icons.incomplete_circle,
              color: session.isCompleted
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.actualDuration.inMinutes} min focus',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(session.startDateTime),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (session.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MeditationBloc>(),
        child: const _ModernSettingsDialog(),
      ),
    );
  }
}

// --- HELPER COMPONENTS ---

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final bool isGlowing;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 50,
    this.iconSize = 24,
    this.color,
    this.isGlowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (color ?? Colors.white).withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: isGlowing
              ? [
                  BoxShadow(
                    color: (color ?? Colors.white).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

class _ModernSettingsDialog extends StatelessWidget {
  const _ModernSettingsDialog();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: BlocBuilder<MeditationBloc, MeditationState>(
        builder: (context, state) {
          return AlertDialog(
            backgroundColor: AppColors.bgTop.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Ambience',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOUNDSCAPES',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...availableTracks.map((track) {
                  final isSelected = state.selectedMusicTrack == track.name;
                  return InkWell(
                    onTap: () => context.read<MeditationBloc>().add(
                      ChangeMusicTrack(track.name),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.music_note
                                : Icons.music_off_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            track.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Text(
                  'VOLUME',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    overlayColor: AppColors.accent.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: state.volume,
                    onChanged: (v) =>
                        context.read<MeditationBloc>().add(ChangeVolume(v)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
