# Flutter and Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase SDKs
-keep class com.google.firebase.** { *; }
-keepnames class com.google.android.gms.measurement.AppMeasurement
-keep class com.google.android.gms.common.** { *; }

# Required for Firebase Authentication
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.android.gms.auth.** { *; }

# Keep Kotlin metadata
-keepattributes EnclosingMethod
-keep class kotlin.Metadata { *; }

# Suppress warnings for classes that may not be present
-dontwarn org.conscrypt.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry