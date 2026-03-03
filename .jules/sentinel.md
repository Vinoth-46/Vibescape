## 2024-05-24 - [CRITICAL] Hardcoded Secrets API Keys and [HIGH] Battery Drain

**Vulnerability:** A hardcoded YouTube API key was found directly embedded in `lib/secrets.dart` (`'YOUR_API_KEY_HERE'`). Also, a high battery drain issue was present due to `StreamBuilder` causing high repaint updates placed inside a `BackdropFilter` block in the Mini Player.
**Learning:** Hardcoded credentials should never be checked into source control as it leads to credential leakage. The `BackdropFilter` widget computes blurred layouts, doing this many times a second via `StreamBuilder`'s continuous listener significantly increases processing cost.
**Prevention:** Always use secure runtime environments or build-time parameters (`--dart-define`) alongside `String.fromEnvironment()` to insert keys safely without risking repo leakage. For Flutter, isolate frequent rebuilds (like progress bars) from high-computation widgets (like `BackdropFilter` or `Opacity`).
