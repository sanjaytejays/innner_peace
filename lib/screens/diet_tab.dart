import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/diet_bloc.dart';
import '../models/diet_models.dart';

// --- THEME CONSTANTS (Matching other screens) ---
class AppColors {
  static const bgTop = Color(0xFF1A1F38);
  static const bgBottom = Color(0xFF101426);
  static const accent = Color(0xFFB589D6);
  static const cardBg = Color(0xFF232946);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white54;
}

class DietTab extends StatefulWidget {
  const DietTab({super.key});

  @override
  State<DietTab> createState() => _DietTabState();
}

class _DietTabState extends State<DietTab> with SingleTickerProviderStateMixin {
  Timer? _timer;
  final TextEditingController _foodInputController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        context.read<DietBloc>().add(UpdateTimer());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _foodInputController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: BlocBuilder<DietBloc, DietState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent, // Allow gradient to show
            body: SafeArea(
              child: Column(
                children: [
                  // --- FASTING HEADER ---
                  _buildFastingHeader(state),

                  // --- TAB BAR ---
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      // --- ADD THIS LINE ---
                      indicatorSize: TabBarIndicatorSize.tab,
                      // --------------------
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
                      dividerColor: Colors.transparent,
                      // Optional: Removes the tap ripple if you want a cleaner "flat" look
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: MaterialStateProperty.resolveWith<Color?>((
                        Set<MaterialState> states,
                      ) {
                        return states.contains(MaterialState.focused)
                            ? null
                            : Colors.transparent;
                      }),
                      tabs: const [
                        Tab(text: 'Today'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  // --- TAB VIEWS ---
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildTodayView(state),
                        _buildHistoryView(state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFastingHeader(DietState state) {
    final bool isFasting = state.activeFasting != null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isFasting
              ? AppColors.accent.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          if (isFasting)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFasting ? "FASTING ACTIVE" : "EATING WINDOW",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isFasting
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFasting ? "You're doing great!" : "Ready to start?",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isFasting
                      ? AppColors.accent.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFasting ? Icons.bolt : Icons.restaurant,
                  color: isFasting ? AppColors.accent : Colors.orange,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Timer Display
          Text(
            _formatDuration(state.currentFastingDuration),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w200,
              fontFamily: 'Monospace',
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(height: 16),

          // Progress Bar
          if (isFasting)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.fastingProgress,
                    backgroundColor: Colors.white10,
                    color: AppColors.accent,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "0%",
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    Text(
                      "Target: ${state.activeFasting!.targetHours}h",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      "100%",
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Buttons
          if (isFasting)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.read<DietBloc>().add(ToggleFasting());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "END FAST",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                _buildFastingOption(16, "16:8"),
                const SizedBox(width: 12),
                _buildFastingOption(18, "18:6"),
                const SizedBox(width: 12),
                _buildFastingOption(20, "20:4"),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFastingOption(int hours, String label) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => context.read<DietBloc>().add(ToggleFasting(hours)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardBg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: AppColors.accent.withOpacity(0.3)),
          ),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTodayView(DietState state) {
    return Column(
      children: [
        // Food Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _foodInputController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "What did you eat?",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) _showMealTypeDialog(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (_foodInputController.text.isNotEmpty) {
                      _showMealTypeDialog(_foodInputController.text);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "TODAY'S MEALS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),

        // Today's Food Log
        Expanded(
          child: state.todayFoodLog.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_food_outlined,
                        size: 50,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "No meals logged today",
                        style: TextStyle(color: Colors.white.withOpacity(0.3)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.todayFoodLog.length,
                  itemBuilder: (context, index) {
                    final item = state.todayFoodLog[index];
                    return _buildFoodCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(DietState state) {
    final foodByDate = state.foodLogsByDate;
    final fastingByDate = state.fastingSessionsByDate;
    final allDates = {...foodByDate.keys, ...fastingByDate.keys}.toList()
      ..sort((a, b) => b.compareTo(a));

    if (allDates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 50, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 10),
            Text(
              "No history yet",
              style: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: allDates.length,
      itemBuilder: (context, index) {
        final dateKey = allDates[index];
        final date = DateTime.parse(dateKey);
        final foods = foodByDate[dateKey] ?? [];
        final fastings = fastingByDate[dateKey] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d').format(date).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (fastings.isNotEmpty) ...[
                ...fastings.map((session) => _buildFastingSessionCard(session)),
                const SizedBox(height: 12),
              ],

              if (foods.isNotEmpty) ...[
                ...foods.map(
                  (food) =>
                      _buildFoodCard(food, showDate: false, isCompact: true),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodCard(
    FoodItem item, {
    bool showDate = true,
    bool isCompact = false,
  }) {
    final icon = _getMealIcon(item.type);
    final color = _getMealColor(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        context.read<DietBloc>().add(DeleteFoodItem(item.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isCompact ? Colors.white.withOpacity(0.03) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(15),
          border: isCompact
              ? null
              : Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          title: Text(
            item.food,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            item.type.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          trailing: Text(
            DateFormat('h:mm a').format(item.dateTime),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFastingSessionCard(FastingSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt, size: 20, color: AppColors.accent),
        ),
        title: Text(
          '${session.duration.inHours}h ${session.duration.inMinutes.remainder(60)}m',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'Target: ${session.targetHours}h',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: session.isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.5),
                  ),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(
                Icons.check_circle,
                color: AppColors.accent.withOpacity(0.5),
                size: 18,
              ),
      ),
    );
  }

  void _showMealTypeDialog(String food) {
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.bgTop.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Meal Type',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mealTypeButton(
                'Breakfast',
                Icons.free_breakfast_rounded,
                Colors.orange,
                food,
              ),
              _mealTypeButton(
                'Lunch',
                Icons.lunch_dining_rounded,
                Colors.green,
                food,
              ),
              _mealTypeButton(
                'Dinner',
                Icons.dinner_dining_rounded,
                Colors.redAccent,
                food,
              ),
              _mealTypeButton(
                'Snack',
                Icons.cookie_rounded,
                Colors.amber,
                food,
              ),
              _mealTypeButton(
                'Water',
                Icons.water_drop_rounded,
                Colors.blueAccent,
                food,
              ),
              _mealTypeButton(
                'Coffee',
                Icons.coffee_rounded,
                Colors.brown,
                food,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealTypeButton(String type, IconData icon, Color color, String food) {
    return InkWell(
      onTap: () {
        context.read<DietBloc>().add(AddFoodItem(food, type));
        _foodInputController.clear();
        Navigator.pop(context);
        FocusScope.of(context).unfocus();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              type,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'snack':
        return Icons.cookie_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Color _getMealColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.greenAccent;
      case 'dinner':
        return Colors.redAccent;
      case 'water':
        return Colors.blueAccent;
      case 'coffee':
        return Colors.brown;
      case 'snack':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
