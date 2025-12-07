# Meditation Tab Setup Instructions

## 🎵 Music Files Setup

To enable background music in the meditation feature, you need to add music files to your project:

### 1. Create the music folder structure:

```
your_project/
  └── assets/
      └── music/
          ├── peaceful.mp3
          ├── nature.mp3
          ├── rain.mp3
          ├── ocean.mp3
          └── flute.mp3
```

### 2. Add your music files:

- **peaceful.mp3** - Calm meditation music
- **nature.mp3** - Nature sounds (birds, forest)
- **rain.mp3** - Rain and thunder sounds
- **ocean.mp3** - Ocean waves
- **flute.mp3** - Zen flute music

You can use any royalty-free meditation music. Here are some sources:

- **Pixabay**: https://pixabay.com/music/
- **Free Music Archive**: https://freemusicarchive.org/
- **YouTube Audio Library**: https://www.youtube.com/audiolibrary

### 3. File Requirements:

- Format: MP3 (recommended)
- Duration: 5-15 minutes (will loop automatically)
- File size: Keep under 5MB for optimal performance

### 4. Alternative - Use Placeholder Files:

If you don't have music files yet, you can create empty MP3 files for testing:

```bash
# Create empty files (macOS/Linux)
touch assets/music/peaceful.mp3
touch assets/music/nature.mp3
touch assets/music/rain.mp3
touch assets/music/ocean.mp3
touch assets/music/flute.mp3
```

The app will still work, but there will be no audio playback.

## 🚀 Complete Setup Steps

1. **Install dependencies:**

```bash
flutter pub get
```

2. **Generate Hive adapters:**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Add music files to assets/music/ folder**

4. **Run the app:**

```bash
flutter run
```

## ✨ Features

### Meditation Tab:

- **Beautiful gradient UI** with dark purple theme
- **4 session durations**: 5, 10, 15, 20 minutes
- **Breathing animation** - pulsing circle during meditation
- **Background music** - 5 different tracks to choose from
- **Volume control** - Adjustable in settings
- **Pause/Resume** - Control your session
- **Progress tracking** - Visual progress bar with remaining time
- **Session history** - Complete log of all meditations
- **Day-wise grouping** - See all sessions by date
- **Completion tracking** - Completed vs. interrupted sessions

### Settings:

- **Music selection** - Choose from 5 different tracks
- **Volume slider** - Adjust audio level (0-100%)
- **Persistent settings** - Saved locally with Hive

## 🎨 UI Highlights

- **Dark theme** with purple gradients
- **Smooth animations** - Breathing circle and transitions
- **Production-ready design** - Modern, polished interface
- **Intuitive controls** - Easy to use buttons and sliders
- **Visual feedback** - Progress bars, status indicators

## 📊 History View

The history tab shows:

- **Date grouping** - All sessions organized by day
- **Session details** - Duration, target time, completion status
- **Time stamps** - When each session started
- **Delete option** - Remove old sessions
- **Completion badges** - Green checkmark for completed sessions

Enjoy your meditation journey! 🧘‍♂️

Music by <a href="https://pixabay.com/users/original_soundtrack-50153119/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=338902">Viacheslav Starostin</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=338902">Pixabay</a>

Music by <a href="https://pixabay.com/users/rockot-1947599/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=184572">Rockot</a> from <a href="https://pixabay.com//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=184572">Pixabay</a>

Music by <a href="https://pixabay.com/users/soundsforyou-4861230/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=114484">Mikhail</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=114484">Pixabay</a>

Music by <a href="https://pixabay.com/users/monkeybandito-42537617/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=415901">Geoff Stanton</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=415901">Pixabay</a>

Music by <a href="https://pixabay.com/users/ønetent-38250704/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=229769">Ønetent</a> from <a href="https://pixabay.com//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=229769">Pixabay</a>
