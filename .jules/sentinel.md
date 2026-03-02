## 2024-05-24 - Hardcoded API Key & Unbounded Stream.periodic
**Vulnerability:** Hardcoded YouTube API Key in source control and an unconstrained Stream.periodic generating infinite background timers.
**Learning:** Hardcoding credentials exposes sensitive information if the repository is public or breached. Additionally, accessing a getter that creates a new Stream.periodic without tracking/caching it leads to massive resource leaks and battery drain, as every widget rebuilding and reading that getter spawns a new un-cancelable background timer.
**Prevention:** Use `String.fromEnvironment` for sensitive build-time injected secrets. Cache Streams instead of creating them dynamically in getters, and ensure they are paused/cancelled when no longer actively listened to or when playback stops.
