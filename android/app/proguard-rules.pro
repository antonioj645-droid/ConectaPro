# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# App classes
-keep class com.conectapro.app.** { *; }

# Play Core (deferred components não usados neste app — evita erro R8)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
