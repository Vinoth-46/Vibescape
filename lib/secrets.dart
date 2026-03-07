class Secrets {
  // Security Enhancement: Use String.fromEnvironment to prevent hardcoding secrets.
  // Pass the key using: --dart-define=YOUTUBE_API_KEY=your_key
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
}
