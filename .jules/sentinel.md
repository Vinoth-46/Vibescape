## 2025-03-05 - Hardcoded Secrets in Config
**Vulnerability:** Found a hardcoded API Key parameter in `secrets.dart`.
**Learning:** Config files like `secrets.dart` will likely be tracked by git or accidentally committed, exposing sensitive keys.
**Prevention:** Using `String.fromEnvironment('YOUTUBE_API_KEY')` provides a safer way to pass secrets during build time (`--dart-define=YOUTUBE_API_KEY=xxx`) preventing them from being pushed to source control.
