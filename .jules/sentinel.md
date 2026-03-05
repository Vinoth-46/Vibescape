## 2024-05-18 - Hardcoded API Key
**Vulnerability:** A hardcoded YouTube API key was found in `lib/secrets.dart`.
**Learning:** Hardcoded API keys present a security risk because they can be easily extracted from the application package, allowing malicious actors to impersonate the app and potentially incur costs or exceed quota limits.
**Prevention:** Use build-time environment variables (`--dart-define`) to inject sensitive information like API keys securely.
