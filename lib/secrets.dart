class Secrets {
  // Obtain your YouTube Data API Key from https://console.cloud.google.com/apis/credentials
  // Provide it at build/run time using: --dart-define=YOUTUBE_API_KEY=your_key_here
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
}
