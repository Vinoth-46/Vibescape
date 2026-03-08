## 2024-05-24 - Sentinel Init
**Vulnerability:** N/A
**Learning:** N/A
**Prevention:** N/A

## 2024-05-24 - Hardcoded Secret Removal
**Vulnerability:** Hardcoded API key placeholder in `lib/secrets.dart` (`static const String youtubeApiKey = 'YOUR_API_KEY_HERE';`). While it was just a placeholder, users might have replaced it with their actual key and committed it accidentally.
**Learning:** Flutter applications should use environment variables (`String.fromEnvironment`) to pass secrets at build time rather than hardcoding them into source files.
**Prevention:** Always use `--dart-define=KEY=value` combined with `String.fromEnvironment('KEY')` for secrets. Never place actual credentials or placeholders that encourage placing credentials in source code.
