````markdown
# 🌿 Inner Peace

**Inner Peace** is a holistic wellness application built with Flutter. It combines mental clarity, physical activity, and dietary discipline into a single, beautiful Glassmorphism-styled interface.

The app features three core pillars: **Meditation**, **Diet (Intermittent Fasting)**, and **Step Tracking**.

---

## ✨ Features

### 🧘 Meditation Focus

- **Breathing Animation:** Visual cues for rhythmic breathing exercises.
- **Ambient Soundscapes:** Background audio support (Peaceful, Rain, Ocean, etc.).
- **Custom Timer:** Flexible duration settings.
- **History Log:** Tracks completed sessions and mindfulness minutes.

### 🍎 Diet & Fasting

- **Intermittent Fasting Timer:** Presets for 16:8, 18:6, and 20:4 fasting windows.
- **Live Status:** Real-time countdown and progress bar for fasting/eating phases.
- **Meal Logger:** Log meals (Breakfast, Lunch, Dinner, Snacks) and Water intake.
- **History:** Comprehensive view of daily logs and fasting achievements.

### 👣 Step Tracker

- **Real-time Counting:** Uses device sensors (Pedometer) to track steps efficiently.
- **Daily Goals:** Visual progress ring towards daily step goals.
- **Metrics:** Automatic calculation of distance (km) and calories burned (kcal).
- **Smart Data:** Handles daily resets and sensor offsets automatically.

### 📊 Unified Dashboard

- **At-a-Glance View:** Aggregates real-time data from all three features.
- **Motivational Quotes:** Daily inspiration.
- **Dark Mode UI:** A consistent, serene, deep-blue glassmorphism aesthetic.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **Language:** Dart
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) (BLoC Pattern)
- **Local Database:** [Hive](https://pub.dev/packages/hive) (NoSQL, lightweight)
- **Sensors:** [pedometer](https://pub.dev/packages/pedometer)
- **Audio:** [audioplayers](https://pub.dev/packages/audioplayers)
- **Permissions:** [permission_handler](https://pub.dev/packages/permission_handler)

---

## 📂 Project Structure

```text
lib/
├── bloc/                # Business Logic Components (State Management)
│   ├── diet_bloc.dart
│   ├── meditation_bloc.dart
│   └── step_bloc.dart
├── models/              # Hive Data Models
│   ├── diet_models.dart
│   ├── meditation_models.dart
│   └── step_models.dart
├── screens/             # UI Screens
│   ├── dashboard_tab.dart
│   ├── diet_tab.dart
│   ├── meditation_tab.dart
│   └── step_tab.dart
└── main.dart            # Entry point & App Configuration
```
````

---

## 🚀 Getting Started

### 1\. Prerequisites

- Flutter SDK installed.
- Android Studio or VS Code.
- **Physical Device:** The Pedometer feature requires a physical sensor; it will not work on most simulators/emulators.

### 2\. Installation

1.  **Clone the repository:**

    ```bash
    git clone [https://github.com/yourusername/inner-peace.git](https://github.com/yourusername/inner-peace.git)
    cd inner-peace
    ```

2.  **Add Assets:**
    Create a folder structure `assets/music/` in the root directory and add your MP3 files (e.g., `peaceful.mp3`, `rain.mp3`).

3.  **Install Dependencies:**

    ```bash
    flutter pub get
    ```

4.  **Run Code Generation:**
    Since the app uses Hive for local storage, you must generate the type adapters.

    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

5.  **Run the App:**

    ```bash
    flutter run
    ```

---

## 📱 Platform Configuration

To ensure the sensors work, add the following permissions.

### Android (`android/app/src/main/AndroidManifest.xml`)

Add the Activity Recognition permission inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

### iOS (`ios/Runner/Info.plist`)

Add the Motion Usage description key:

```xml
<key>NSMotionUsageDescription</key>
<string>We use motion detection to track your daily steps.</string>
```

---

## 📦 Dependencies

Ensure your `pubspec.yaml` includes these packages:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  intl: ^0.18.1
  pedometer: ^4.0.0
  permission_handler: ^11.0.1
  audioplayers: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
```

---

## 🤝 Contributing

Contributions are welcome\!

1.  Fork the Project.
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the Branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

<!-- end list -->

```

```
