# MediaPipe proto classes referenced at runtime via reflection.
-keep class com.google.mediapipe.proto.** { *; }

# LiteRT-LM native bindings used by flutter_gemma.
-dontwarn com.google.ai.edge.litertlm.**
-keep class com.google.ai.edge.litertlm.** { *; }
