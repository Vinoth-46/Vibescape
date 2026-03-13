## 2025-02-14 - Hardcoded YouTube API Key
**Vulnerability:** Found a hardcoded YouTube API key `YOUR_API_KEY_HERE` inside `lib/secrets.dart`.
**Learning:** Hardcoded credentials can be leaked if the codebase is exposed or shared, potentially leading to unauthorized usage and quota exhaustion.
**Prevention:** Always use environment variables passed at build time (e.g., `String.fromEnvironment('YOUTUBE_API_KEY')` with `--dart-define`) to supply sensitive credentials.
