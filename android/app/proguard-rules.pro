# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Audio Service
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.AudioServiceApplication { *; }
-keep class com.ryanheise.audioservice.AudioServiceActivity { *; }
-keep class com.ryanheise.audioservice.AudioServiceFragmentActivity { *; }
-keep class com.ryanheise.audioservice.MediaButtonReceiver { *; }

# Just Audio
-keep class com.ryanheise.just_audio.** { *; }

# Media Metadata Retriever
-keep class com.ryanheise.metadataretriever.** { *; }

# Google Play Core (Flutter internal references)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Just Audio & Media3 / ExoPlayer (Critical for Release)
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
