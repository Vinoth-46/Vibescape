# Offline Music Player

A feature-rich offline music player application built with Flutter. This app allows users to play their local music files with a beautiful and intuitive user interface.

## 📸 Screenshots

<!-- Add screenshots here -->
![Home Screen](assets/screenshots/home.png) | ![Now Playing](assets/screenshots/now_playing.png)
--- | ---
**Home** | **Now Playing**

## ✨ Features

- 🎵 **Offline Playback**: Play local audio files directly from your device.
- 📂 **File Management**: Organized view of songs, albums, and artists.
- 🎨 **Beautiful UI**: Modern and clean interface with smooth animations.
- 📝 **Playlist Support**: Create and manage your own playlists.
- 🔍 **Search**: Quickly find your favorite tracks.
- 🎛️ **Background Playback**: Continue listening while using other apps.
- 📱 **Responsive Design**: optimized for various screen sizes.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Audio Playback**: [just_audio](https://pub.dev/packages/just_audio) & [audio_service](https://pub.dev/packages/audio_service)
- **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) & [on_audio_query](https://pub.dev/packages/on_audio_query)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) configured for Flutter development.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/offline_music_player.git
    cd offline_music_player
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 📦 Building for Release (Android)

To generate a release APK:

1.  Update `android/key.properties` with your signing configuration (if applicable).
2.  Run the build command:
    ```bash
    flutter build apk --release
    ```
    The output APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
