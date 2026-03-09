## 2024-05-24 - Hardcoded Secrets are a Critical Vulnerability
**Vulnerability:** A hardcoded YouTube API key was found in `lib/secrets.dart` which could be exposed via source control or reverse engineering.
**Learning:** Hardcoded credentials represent a critical risk as they bypass all security controls. Using compile-time definitions via `--dart-define` allows secrets to be passed securely during the CI/CD pipeline.
**Prevention:** Never hardcode secrets in source code. Always utilize `String.fromEnvironment()` or secure environment variables to manage sensitive configuration at build time.
