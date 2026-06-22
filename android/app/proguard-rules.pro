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

# ARCore & SceneView
-keep class com.google.ar.core.** { *; }
-keep class com.google.ar.sceneform.** { *; }
-keep class io.github.sceneview.** { *; }
-keep class com.gorisse.thomas.sceneform.** { *; }
-dontwarn com.google.ar.core.**
-dontwarn com.google.ar.sceneform.**
-dontwarn io.github.sceneview.**
