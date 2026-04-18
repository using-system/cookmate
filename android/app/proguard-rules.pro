# MediaPipe proto classes are referenced by the framework but not shipped
# in the classpath. The -dontwarn tells R8 to treat these missing classes
# as non-fatal; the -keep ensures any that DO exist are not stripped.
-dontwarn com.google.mediapipe.proto.**
-keep class com.google.mediapipe.proto.** { *; }
-keep class com.google.mediapipe.framework.** { *; }

# LiteRT-LM native bindings used by flutter_gemma.
-dontwarn com.google.ai.edge.litertlm.**
-keep class com.google.ai.edge.litertlm.** { *; }
