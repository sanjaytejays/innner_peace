import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// --- CONSTANTS ---
const String kStepBox = 'step_tracker_box';
const int kDailyGoal = 10000;

/// Main Widget to be used in your Tab
class StepTrackerPage extends StatelessWidget {
  const StepTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StepController(),
      child: const _StepTrackerView(),
    );
  }
}

/// The Controller (State Management & Logic)
class StepController extends ChangeNotifier {
  late Box _box;
  StreamSubscription<StepCount>? _subscription;

  // State Variables
  int _todaySteps = 0;
  String _status = 'Initializing...';
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  // Getters
  int get todaySteps => _todaySteps;
  String get status => _status;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get history => _history;
  double get progress => (_todaySteps / kDailyGoal).clamp(0.0, 1.0);

  StepController() {
    _init();
  }

  Future<void> _init() async {
    // 1. Open Hive Box
    if (!Hive.isBoxOpen(kStepBox)) {
      await Hive.openBox(kStepBox);
    }
    _box = Hive.box(kStepBox);

    // 2. Load History
    _loadHistory();

    // 3. Request Permissions & Start Listening
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Android requires ACTIVITY_RECOGNITION
    var status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _startListening();
    } else if (status.isPermanentlyDenied) {
      _status = 'Permission Denied. Please enable in settings.';
      _isLoading = false;
      notifyListeners();
    } else {
      _status = 'Waiting for permission...';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startListening() {
    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      onDone: _onStepCountDone,
    );
    _status = 'Tracking active';
    _isLoading = false;
    notifyListeners();
  }

  void _onStepCount(StepCount event) {
    final int sensorSteps = event.steps;
    final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // --- CORE LOGIC: Handle Daily Reset ---
    // The sensor returns cumulative steps since boot. We must track an offset.

    // 1. Get the last date we recorded steps
    String? lastDate = _box.get('last_record_date');
    int? dayOffset = _box.get('day_offset');

    // 2. If it's a new day (or first run), reset the offset
    if (lastDate != todayKey) {
      // Archive yesterday's steps if they exist
      if (lastDate != null) {
        _archiveDay(lastDate, _box.get('steps_for_$lastDate', defaultValue: 0));
      }

      // Set new offset to current sensor value
      // This means steps start at 0 for the new day relative to the sensor
      dayOffset = sensorSteps;
      _box.put('day_offset', dayOffset);
      _box.put('last_record_date', todayKey);

      // Reset today's steps in UI
      _todaySteps = 0;
    } else {
      // Same day: Calculate real steps
      // Logic: RealSteps = SensorTotal - Offset
      if (dayOffset == null) {
        // Should not happen if logic holds, but safety fallback
        dayOffset = sensorSteps;
        _box.put('day_offset', dayOffset);
      }
      _todaySteps = sensorSteps - dayOffset;
    }

    // 3. Save Today's count
    _box.put('steps_for_$todayKey', _todaySteps);

    // 4. Update UI
    notifyListeners();
  }

  void _archiveDay(String date, int steps) {
    List historyList = _box.get('history', defaultValue: []);
    // Check if date already exists to avoid duplicates
    bool exists = historyList.any((element) => element['date'] == date);
    if (!exists && steps > 0) {
      historyList.add({'date': date, 'steps': steps});
      _box.put('history', historyList);
      _loadHistory(); // Refresh list
    }
  }

  void _loadHistory() {
    List rawList = _box.get('history', defaultValue: []);
    // Convert dynamic list to strongly typed map and reverse (newest first)
    _history = List<Map<String, dynamic>>.from(rawList).reversed.toList();
    notifyListeners();
  }

  void _onStepCountError(error) {
    _status = 'Sensor Error: $error';
    notifyListeners();
  }

  void _onStepCountDone() {
    _status = 'Sensor Closed';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// The UI View
class _StepTrackerView extends StatelessWidget {
  const _StepTrackerView();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StepController>(context);

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER SECTION ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
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
                          const Text(
                            "Today's Activity",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              controller.status.contains('Error') ||
                                  controller.status.contains('Denied')
                              ? Colors.red.withOpacity(0.1)
                              : Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          controller.status.contains('Tracking')
                              ? "Active"
                              : "Inactive",
                          style: TextStyle(
                            color: controller.status.contains('Tracking')
                                ? Colors.teal
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- CIRCULAR PROGRESS ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CircularProgressIndicator(
                          value: controller.progress,
                          strokeWidth: 15,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.teal,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 40,
                            color: Colors.teal,
                          ),
                          Text(
                            "${controller.todaySteps}",
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            "/ $kDailyGoal steps",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Keep moving! You're doing great.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "History",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // --- HISTORY LIST ---
            Expanded(
              child: controller.history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "No history yet.\nStart walking to build your log!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.history.length,
                      itemBuilder: (context, index) {
                        final log = controller.history[index];
                        final dateStr = log['date'];
                        final steps = log['steps'];
                        final DateTime date = DateFormat(
                          'yyyy-MM-dd',
                        ).parse(dateStr);
                        final bool goalMet = steps >= kDailyGoal;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: goalMet
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                goalMet
                                    ? Icons.emoji_events
                                    : Icons.directions_walk,
                                color: goalMet ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              DateFormat('EEEE, MMM d').format(date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              "$steps",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
