# Preserve Flutter entry points and plugin communication.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**