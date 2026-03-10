class Secrets {
  // Retrieves the YouTube Data API Key from the environment at build time.
  // Obtain one from https://console.cloud.google.com/apis/credentials
  // Build with: flutter build apk --dart-define=YOUTUBE_API_KEY=<your_key>
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
}
