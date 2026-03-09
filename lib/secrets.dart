class Secrets {
  // TODO: Add your YouTube Data API Key here.
  // Obtain one from https://console.cloud.google.com/apis/credentials
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
}
