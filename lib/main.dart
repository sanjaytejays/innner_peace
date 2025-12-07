import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inner_peace/screens/dashboard_tab.dart';

// --- IMPORTS FOR YOUR BLOCS ---
import 'bloc/diet_bloc.dart';
import 'bloc/meditation_bloc.dart';
import 'bloc/step_bloc.dart';

// --- IMPORTS FOR YOUR MODELS ---
import 'models/diet_models.dart';
import 'models/meditation_models.dart';
import 'models/step_models.dart';

// --- IMPORTS FOR YOUR SCREENS ---
import 'screens/diet_tab.dart';
import 'screens/meditation_tab.dart'; // Ensure this file has MeditationTabWidget
import 'screens/step_tab.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive
  await Hive.initFlutter();

  // 3. Register Adapters
  // We use try-catch blocks to prevent errors during Hot Restart
  try {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FoodItemAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(FastingSessionAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(MeditationSessionAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(DailyStepLogAdapter());
  } catch (e) {
    debugPrint('Adapter registration error (ignored): $e');
  }

  runApp(const MyApp());
}

// --- GLOBAL THEME COLORS ---
class AppColors {
  static const bgTop = Color(0xFF1A1F38);
  static const bgBottom = Color(0xFF101426);
  static const navBarBg = Color(0xFF232946);
  static const accent = Color(0xFFB589D6);
  static const unselected = Colors.grey;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inner Peace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgTop,
        useMaterial3: true,
        fontFamily: 'Sans', // Optional: Set a nice font if you have one
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
          surface: AppColors.navBarBg,
        ),
      ),
      // 4. Initialize All Blocs here
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => DietBloc()..initialize()),
          BlocProvider(create: (context) => MeditationBloc()..initialize()),
          BlocProvider(create: (context) => StepBloc()..initialize()),
        ],
        child: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // 5. Screen List
  final List<Widget> _tabs = [
    const DashboardTab(), // Index 0
    const StepTrackerPage(), // Index 1
    const DietTab(), // Index 2
    const MeditationTabWidget(), // Index 3 (Ensure class name matches your file)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody allows content to scroll BEHIND the floating nav bar
      extendBody: true,
      body: _tabs[_currentIndex],
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.navBarBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Home'),
              _buildNavItem(1, Icons.directions_walk_rounded, 'Steps'),
              _buildNavItem(2, Icons.restaurant_rounded, 'Diet'),
              _buildNavItem(3, Icons.self_improvement_rounded, 'Focus'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.unselected,
              size: 24,
            ),
            // Text only appears when selected
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
