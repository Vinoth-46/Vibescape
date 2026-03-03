class Secrets {
  // TODO: Add your YouTube Data API Key here.
  // Obtain one from https://console.cloud.google.com/apis/credentials
  // Pass the key at build time using: --dart-define=YOUTUBE_API_KEY=your_key
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
}
