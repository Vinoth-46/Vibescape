## 2024-03-07 - Hardcoded API Key Exposure
**Vulnerability:** The YouTube API key was being hardcoded directly in `lib/secrets.dart` which encourages committing real credentials to the codebase.
**Learning:** Hardcoding credentials in source code exposes them to version control, making them accessible to anyone with repository access. This pattern was likely used for convenience during early development.
**Prevention:** Always use environment variables or build-time configuration (like `String.fromEnvironment`) to inject secrets. For Flutter apps, use `--dart-define=KEY=value` during the build process to provide sensitive credentials safely.
