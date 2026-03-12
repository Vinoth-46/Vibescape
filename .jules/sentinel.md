## 2024-05-18 - Hardcoded API Key Exposure
**Vulnerability:** A hardcoded YouTube API key placeholder ('YOUR_API_KEY_HERE') was found in `lib/secrets.dart` which required manually entering the API key directly into the codebase.
**Learning:** Hardcoding secrets directly in version control is dangerous as it leaks them to anyone with repository access. It also makes configuring CI/CD pipelines and deployment complex as developers have to manually remove the secret before committing.
**Prevention:** Use environment variables passed at build time (e.g., `--dart-define=YOUTUBE_API_KEY=<your_key>`) and access them using `String.fromEnvironment('YOUTUBE_API_KEY')` in Dart code.
