# Preview beta.11 release-test setup follow-up

[Beta.11 qualification](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/releases/preview-2.6.0-beta.11.md)
passed before publication. The release took longer than necessary; this was not
all time inherently required by the app's model or release gates.

A native PGN intent-routing correction required refreezing source and repeating
exact-source qualification. An ungranted adb content-URI fixture complicated that
diagnosis; valid provider imports and invalid/ungranted imports must be distinct.

Avoidable operator problems then added retries: a System UI ANR held focus during
clipboard checks; a five-second sound-load timeout occurred under heavy Mac load;
and the custom APK driver assumed an EditText node, did not tolerate a transient
malformed snapshot, and lacked Pillow. Signature reconstruction also needed its
Python dependencies installed correctly. The final unchanged-source full native
run passed, with earlier failures retained as diagnostics, not counted as passes.
The production APK's 10,000-game import took about 654 seconds on that loaded
emulator; that is not a physical-phone performance measurement. Signing was
initially serialized unnecessarily, and stale guide text caused a second docs CI.

The shared [release-test setup](../RELEASE_TEST_SETUP.md) now provides complete
dependency installation, early host/device/focus diagnostics, bounded UI reads
and editable semantics. CI installs the same operator requirements in both
repositories. The documented schedule overlaps independent work, isolates device
mutations, distinguishes driver repairs from source changes and prepares the
full documentation pass before CI. Required signing, reproduction, native,
upgrade, public-download and cleanup gates remain unchanged. No app release or
Stable promotion is part of this tooling follow-up.
