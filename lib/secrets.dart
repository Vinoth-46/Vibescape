class Secrets {
  // Obtain one from https://console.cloud.google.com/apis/credentials
  // Then pass via build args: --dart-define=YOUTUBE_API_KEY=your_key_here
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
}
