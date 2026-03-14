## 2024-06-13 - [Stream Position Battery Drain]
**Vulnerability:** The application was using Stream.periodic for the audio position stream causing excessive and continuous events even if the stream wasn't actively being listened to, resulting in battery drain.
**Learning:** `AudioService.position` stream isn't available in newer versions of audio_service. If a custom stream isn't managed properly via broadcast and `Timer.periodic`, it will fire continuously regardless of subscriptions.
**Prevention:** Implement position streams manually using a cached `StreamController.broadcast` that only starts the timer on `onListen` and cancels it on `onCancel`.

## 2024-06-13 - [Hardcoded YouTube API Key]
**Vulnerability:** YouTube API key was previously mentioned in `secrets.dart` which meant that users would have to add their API keys in plain text to code. Hardcoding secrets in source files or expecting them to be hardcoded is insecure as they might get checked into version control.
**Learning:** Dart's `String.fromEnvironment` should be used instead of variables in simple files.
**Prevention:** Always retrieve keys through `--dart-define` and `String.fromEnvironment()`.
