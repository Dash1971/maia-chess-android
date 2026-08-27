# ONNX Runtime's native JNI layer resolves these classes and members by their
# original Java names. Renaming them causes a fatal GetMethodID/FindClass abort.
-keep class ai.onnxruntime.** { *; }
-keep interface ai.onnxruntime.** { *; }
-keep enum ai.onnxruntime.** { *; }
