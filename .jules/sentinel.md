## 2024-03-11 - Hardcoded YouTube API Key

**Vulnerability:** The YouTube Data API Key was hardcoded in `lib/secrets.dart` as a placeholder (`YOUR_API_KEY_HERE`), meaning developers might replace it with a real key and accidentally commit it to source control.

**Learning:** Hardcoding API keys in source files, even as placeholders, establishes an insecure pattern that easily leads to accidental key exposure when developers add their own keys.

**Prevention:** Use Dart's `String.fromEnvironment('YOUTUBE_API_KEY')` to read the key at build time and pass it via the command line (`--dart-define=YOUTUBE_API_KEY=<your_key>`). This completely separates secrets from the codebase.
