# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Audio Service - Keep everything
-keep class com.ryanheise.audioservice.** { *; }
-keepclassmembers class com.ryanheise.audioservice.** { *; }

# Just Audio - Keep everything including internal classes
-keep class com.ryanheise.just_audio.** { *; }
-keepclassmembers class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.** { *; }

# On Audio Query
-keep class com.lucasjosino.on_audio_query.** { *; }
-keep class com.lucasjosino.** { *; }

# Media Metadata Retriever
-keep class com.ryanheise.metadataretriever.** { *; }

# Google Play Core (Flutter internal references)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Media3 / ExoPlayer (Critical for Release) - COMPREHENSIVE
-keep class androidx.media3.** { *; }
-keepclassmembers class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keepclassmembers class com.google.android.exoplayer2.** { *; }
-keep class androidx.media.** { *; }

# ExoPlayer extension - don't strip decoder factories
-keep class androidx.media3.exoplayer.** { *; }
-keep class androidx.media3.extractor.** { *; }
-keep class androidx.media3.datasource.** { *; }
-keep class androidx.media3.decoder.** { *; }
-keep class androidx.media3.common.** { *; }
-keep class androidx.media3.session.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Don't obfuscate any audio-related classes
-keepnames class * extends android.media.MediaPlayer
-keepnames class * extends android.media.AudioTrack
-keepnames class * extends android.media.MediaCodec

# Keep Guava classes that ExoPlayer uses
-dontwarn com.google.common.**
-keep class com.google.common.** { *; }
-dontwarn com.google.errorprone.annotations.**

# JSON/Gson (if used by audio libraries)
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep callback interfaces  
-keepclassmembers class * {
    public void on*(...);
}

# Android framework classes needed by audio
-keep class android.media.** { *; }
-keep class android.content.** { *; }

# Suppress R8 warnings for optional dependencies
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn sun.misc.Unsafe

# Keep reflection used by audio plugins
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
