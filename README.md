# 🎵 Isai - Offline Music Player

A feature-rich offline music player application built with Flutter. Enjoy your local music library with a beautiful, modern interface.

> 💡 **Concept & Ideas**: Designed and envisioned by **Vinoth**
> 
> 🤖 **Technical Implementation**: Built and debugged with **Google's Gemini AI (Antigravity)**

---

## 📸 Screenshots

<p align="center">
  <img src="screenshots/library.jpg" width="250" alt="Library Screen"/>
  <img src="screenshots/now_playing.jpg" width="250" alt="Now Playing Screen"/>
  <img src="screenshots/settings.jpg" width="250" alt="Settings Screen"/>
</p>

| Library | Now Playing | Settings |
|---------|-------------|----------|
| Browse all your songs | Full playback controls | Customize your experience |

---

## ✨ Features

### 🎧 Online Music Streaming
- **JioSaavn & YouTube Integration** - Search and stream directly from the largest online catalog.
- **Trending & Explore** - Discover new music filtered by your preferred language (Hindi, English, Punjabi, Tamil, Telugu, Malayalam).
- **Download for Offline Use** - Cache streaming songs locally with one tap to listen without internet.
- **Smart Fallbacks** - Cross-references JioSaavn and YouTube dynamically to ensure high availability.

### 🎵 Local Music Playback
- **Offline Library** - Play local audio files directly from your device storage seamlessly.
- **Background Playback & Lock Screen** - Control playback from notification and lock screen via `audio_service`.
- **Folder Selection** - Filter exactly which directories to scan for local music (excludes voice memos!).
- **Playlists & Favorites** - Create your perfect custom collections mixing local and streaming songs.

### ⚙️ Premium Utilities
- **Sleep Timer** - Automatically pause playback after a set time, or precisely at the **End of the Track**.
- **In-App Updater** - Automatically checks GitHub for new `.apk` releases and installs updates over-the-air!
- **Theme Support** - Glassmorphism UI with Apple-inspired premium Light & Dark themes.
- **Custom Filters** - Hide short tracks via the customizable minimum duration filter.

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| [Flutter](https://flutter.dev/) | Cross-platform framework |
| [Dart](https://dart.dev/) | Programming language |
| [Provider](https://pub.dev/packages/provider) | State management |
| [just_audio](https://pub.dev/packages/just_audio) | Audio playback engine |
| [audio_service](https://pub.dev/packages/audio_service) | Background audio & notifications |
| [on_audio_query](https://pub.dev/packages/on_audio_query) | Query device music library |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Local storage |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/Vinoth-46/Music_player.git
cd Music_player

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📦 Building for Release

```bash
# Generate release APK
flutter build apk --release

# APK location
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 App Screens

| Screen | Description |
|--------|-------------|
| **Library** | Browse all songs alphabetically with artwork |
| **Favorites** | Quick access to your favorite songs |
| **Playlists** | Create and manage custom playlists |
| **Folders** | Browse music organized by device folders |
| **Settings** | Theme, folder selection, duration filter |
| **Now Playing** | Full player with artwork and controls |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 👨‍💻 Developer

**Vinoth** - Flutter Developer

[![GitHub](https://img.shields.io/badge/GitHub-Vinoth--46-black?style=flat&logo=github)](https://github.com/Vinoth-46)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-vinoth465-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/vinoth465/)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">Made with ❤️ by Vinoth | Powered by 🤖 Gemini AI</p>
