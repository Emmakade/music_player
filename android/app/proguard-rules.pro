# Keep audio_service background service
-keep class com.ryanheise.audioservice.** { *; }

# Keep Flutter embedding classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep service registration
-keep class android.support.v4.media.** { *; }
-keep class android.media.session.** { *; }