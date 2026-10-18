# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods and annotated fields
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep secure storage
-keep class androidx.security.crypto.** { *; }

# Keep geolocator classes
-keep class com.baseflow.geolocator.** { *; }

# Suppress Play Store Split Install / Deferred Component warnings for R8
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
