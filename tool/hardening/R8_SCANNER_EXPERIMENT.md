# R8 scanner experiment

This branch tests whether Android release minification can remove Flutter's
unused Google Play Core deferred-component references without changing Mobile
Maia's behavior. It is not release authorization.

## Acceptance gates

Before this change can be merged into a stable release:

1. F-Droid's APK scanner must report none of the six Play Core findings that it
   reports for the unminified v2.1.1 APK.
2. The release verifier must confirm the stable package ID, version metadata,
   permissions, three intended ABIs, Maia model, and unsigned state.
3. Two clean Linux builds from the same commit must be byte-identical.
4. Flutter, native-engine, Stockfish, Maia/ONNX, saved-game upgrade, Chessnut
   Bluetooth, and Android integration tests must pass.
5. APK and DEX size changes must be recorded. Size reduction alone is not a
   reason to accept a functional or compatibility regression.

Keep `isShrinkResources = false`: this experiment changes only Java/Kotlin
shrinking, optimization, and obfuscation. `proguard-rules.pro` preserves ONNX
Runtime classes whose original names are resolved through JNI.

If any gate fails or runtime confidence remains insufficient, close the draft
PR and leave the canonical release unminified. No tag, signing, or publication
belongs in this experiment.
