import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/step_bloc.dart';

// Reuse AppColors
class AppColors {
  static const bgTop = Color(0xFF1A1F38);
  static const bgBottom = Color(0xFF101426);
  static const accent = Color(0xFFB589D6);
  static const cardBg = Color(0xFF232946);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white54;
}

class StepTrackerPage extends StatelessWidget {
  const StepTrackerPage({super.key});

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
          // FIX: Updated to StepTrackerState
          child: BlocBuilder<StepBloc, StepTrackerState>(
            builder: (context, state) {
              if (state.status == StepStatus.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(state),
                      const SizedBox(height: 30),
                      _buildMainProgress(state),
                      const SizedBox(height: 30),
                      _buildStatsGrid(state),
                      const SizedBox(height: 30),
                      _buildHistoryHeader(),
                    ]),
                  ),
                  _buildHistoryList(state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // FIX: Updated argument type to StepTrackerState
  Widget _buildHeader(StepTrackerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(DateTime.now()).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Daily Movement',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: state.status == StepStatus.active
                  ? Colors.greenAccent.withOpacity(0.1)
                  : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.status == StepStatus.active ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                color: state.status == StepStatus.active
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIX: Updated argument type to StepTrackerState
  Widget _buildMainProgress(StepTrackerState state) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 15,
            color: Colors.white.withOpacity(0.05),
            strokeCap: StrokeCap.round,
          ),
        ),
        SizedBox(
          width: 220,
          height: 220,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: state.progress),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 15,
              color: AppColors.accent,
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk,
              color: AppColors.accent,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.decimalPattern().format(state.todaySteps),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            Text(
              'Goal: ${NumberFormat.decimalPattern().format(state.dailyGoal)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // FIX: Updated argument type to StepTrackerState
  Widget _buildStatsGrid(StepTrackerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.place_outlined,
              'Distance',
              '${state.distanceKm} km',
              Colors.cyanAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              Icons.local_fire_department_rounded,
              'Calories',
              '${state.caloriesBurned} kcal',
              Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'LAST 7 DAYS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // FIX: Updated argument type to StepTrackerState
  Widget _buildHistoryList(StepTrackerState state) {
    if (state.history.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No step history recorded yet.\nKeep walking!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final log = state.history[index];
          final date = DateFormat('yyyy-MM-dd').parse(log.dateKey);
          final isGoalMet = log.steps >= log.goal;

          if (index >= 7) return null;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGoalMet
                        ? Colors.greenAccent.withOpacity(0.1)
                        : AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGoalMet ? Icons.star_rounded : Icons.directions_walk,
                    color: isGoalMet ? Colors.greenAccent : AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Goal: ${NumberFormat.decimalPattern().format(log.goal)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.decimalPattern().format(log.steps),
                  style: TextStyle(
                    color: isGoalMet ? Colors.greenAccent : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }, childCount: state.history.length),
      ),
    );
  }
}
