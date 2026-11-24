# TensorFlow Lite — keep all classes to prevent R8 stripping GPU delegate etc.
-keep class org.tensorflow.** { *; }
-keep interface org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Flutter & Dart JNI
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}
