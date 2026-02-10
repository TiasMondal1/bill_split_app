# Keep ML Kit Text Recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep Google ML Kit Commons
-keep class com.google_mlkit_commons.** { *; }

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
