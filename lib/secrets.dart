class Secrets {
  // Obtain a YouTube Data API Key from https://console.cloud.google.com/apis/credentials
  // Pass it at build time using: --dart-define=YOUTUBE_API_KEY=your_api_key
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
}
