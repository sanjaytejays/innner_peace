import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// --- BLOC IMPORTS ---
import '../bloc/step_bloc.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/meditation_bloc.dart';

// --- STATE/MODEL IMPORTS ---
// We need these to access the specific properties (like .progress, .todaySteps)
import '../models/meditation_models.dart';
// Note: StepTrackerState is defined in step_bloc.dart
// Note: DietState is defined in diet_bloc.dart

// --- THEME CONSTANTS ---
class AppColors {
  static const bgTop = Color(0xFF1A1F38);
  static const bgBottom = Color(0xFF101426);
  static const accent = Color(0xFFB589D6);
  static const cardBg = Color(0xFF232946);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white54;
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header & Greeting
              SliverToBoxAdapter(child: _buildHeader()),

              // 2. Motivational Quote
              SliverToBoxAdapter(child: _buildQuoteSection()),

              // 3. Grid: Steps & Fasting (Side by Side)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: const [_StepProgressCard(), _FastingStatusCard()],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 4. List: Meditation & Diet Summaries
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _MeditationSummaryCard(),
                    const SizedBox(height: 16),
                    const _DietSummaryCard(),
                    const SizedBox(height: 100), // Bottom padding for Nav Bar
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    String greeting = 'Good Morning';
    if (now.hour >= 12) greeting = 'Good Afternoon';
    if (now.hour >= 17) greeting = 'Good Evening';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(now).toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            greeting,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: AppColors.accent, size: 30),
          SizedBox(height: 8),
          Text(
            "Peace comes from within. Do not seek it without.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "- Buddha",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 1. FETCHING STEP DATA ---
class _StepProgressCard extends StatelessWidget {
  const _StepProgressCard();

  @override
  Widget build(BuildContext context) {
    // Listens to StepTrackerState
    return BlocBuilder<StepBloc, StepTrackerState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.directions_walk, color: Colors.cyanAccent),
                  Text(
                    "STEPS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: state.progress, // Data from Bloc
                        strokeWidth: 8,
                        backgroundColor: Colors.white10,
                        color: Colors.cyanAccent,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      "${(state.progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NumberFormat.compact().format(
                      state.todaySteps,
                    ), // Data from Bloc
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Goal: ${NumberFormat.compact().format(state.dailyGoal)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- 2. FETCHING DIET (FASTING) DATA ---
class _FastingStatusCard extends StatelessWidget {
  const _FastingStatusCard();

  @override
  Widget build(BuildContext context) {
    // Listens to DietState
    return BlocBuilder<DietBloc, DietState>(
      builder: (context, state) {
        final isFasting = state.activeFasting != null; // Check if active

        String durationText = "--:--";
        if (isFasting) {
          final d = state.currentFastingDuration; // Calculate duration
          durationText =
              "${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}";
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isFasting
                ? AppColors.accent.withOpacity(0.1)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isFasting
                  ? AppColors.accent.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.bolt,
                    color: isFasting ? Colors.yellowAccent : Colors.grey,
                  ),
                  const Text(
                    "FASTING",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      isFasting ? durationText : "OFF",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontFamily: 'Monospace',
                      ),
                    ),
                    if (isFasting)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: state.fastingProgress,
                            minHeight: 4,
                            backgroundColor: Colors.white10,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                isFasting ? "Active Phase" : "Eating Window",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isFasting ? Colors.yellowAccent : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- 3. FETCHING MEDITATION DATA ---
class _MeditationSummaryCard extends StatelessWidget {
  const _MeditationSummaryCard();

  @override
  Widget build(BuildContext context) {
    // Listens to MeditationState
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        // Logic to sum up today's minutes
        final now = DateTime.now();
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final todaySessions = state.sessionsByDate[todayKey] ?? [];
        int totalMinutes = 0;
        for (var s in todaySessions) {
          totalMinutes += s.actualDuration.inMinutes;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mindfulness",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "$totalMinutes",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "min today",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (totalMinutes > 0)
                const Icon(Icons.check_circle, color: Colors.greenAccent),
            ],
          ),
        );
      },
    );
  }
}

// --- 4. FETCHING DIET (MEALS) DATA ---
class _DietSummaryCard extends StatelessWidget {
  const _DietSummaryCard();

  @override
  Widget build(BuildContext context) {
    // Listens to DietState for food logs
    return BlocBuilder<DietBloc, DietState>(
      builder: (context, state) {
        // Calculate Meal vs Water count
        final waterCount = state.todayFoodLog
            .where((i) => i.type.toLowerCase() == 'water')
            .length;
        final mealCount = state.todayFoodLog
            .where((i) => i.type.toLowerCase() != 'water')
            .length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                Icons.water_drop,
                Colors.blueAccent,
                "$waterCount",
                "Water",
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildMiniStat(
                Icons.restaurant,
                Colors.orangeAccent,
                "$mealCount",
                "Meals",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
