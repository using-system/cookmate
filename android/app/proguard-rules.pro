# MediaPipe proto classes referenced by the framework at runtime.
# R8 cannot see these through its static analysis, so they must be kept.
-dontwarn com.google.mediapipe.proto.**
-keep class com.google.mediapipe.proto.** { *; }

# LiteRT / TensorFlow Lite native bindings
-dontwarn com.google.ai.edge.**
-keep class com.google.ai.edge.** { *; }
