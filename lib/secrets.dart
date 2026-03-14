class Secrets {
  // TODO: Add your YouTube Data API Key here.
  // Obtain one from https://console.cloud.google.com/apis/credentials
  // Retrieved via --dart-define=YOUTUBE_API_KEY
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
}
