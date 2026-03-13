class Secrets {
  // TODO: Add your YouTube Data API Key here.
  // Obtain one from https://console.cloud.google.com/apis/credentials
  // The API key should be provided via --dart-define=YOUTUBE_API_KEY=<your_key>
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
}
