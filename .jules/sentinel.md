
## 2026-03-10 - Hardcoded API Key and Battery Drain via Unmanaged Stream
**Vulnerability:** YouTube API key was hardcoded in `lib/secrets.dart`. Additionally, an unmanaged `Stream.periodic` in `AudioPlayerController` ran continuously to poll audio position, causing unnecessary battery drain even when the UI was not observing it.
**Learning:** Hardcoded keys expose access credentials to version control and potential misuse. Unmanaged periodic streams in state controllers, especially those querying device state frequently, will consume CPU and drain the battery if not paused when unused.
**Prevention:** Always retrieve sensitive credentials via environment variables (e.g., `String.fromEnvironment`) at build time rather than hardcoding. Manage periodic streams as broadcast streams with `onListen` and `onCancel` callbacks to pause execution when there are no active listeners.
