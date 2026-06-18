# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Hive
-keep class hive.** { *; }
-keep class com.hivedb.** { *; }

# Flutter deferred components (Play Core)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
