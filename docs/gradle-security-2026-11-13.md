# Gradle security update — 13 November 2026

Gradle 9.9.1 replaces 9.8.1 before the Preview 2.6 qualification build. The 10 November advisories affect the old pin: version-catalog code execution (GHSA-3cfg-jpcr-gfp3), daemon-registry trust (GHSA-gqrr-4j89-5267) and stale registry/port squatting (GHSA-pcp8-98xm-c6pr). All are patched in 9.9.1.

Sources: [official release notes](https://docs.gradle.org/9.9.1/release-notes.html), [catalog advisory](https://github.com/gradle/gradle/security/advisories/GHSA-3cfg-jpcr-gfp3), [registry advisory](https://github.com/gradle/gradle/security/advisories/GHSA-gqrr-4j89-5267), [stale registry advisory](https://github.com/gradle/gradle/security/advisories/GHSA-pcp8-98xm-c6pr).

The official all-distribution SHA-256 is `f20c816177c0ff192881874852260771b462903aef3e794b0dac4759d1fda284`; the official wrapper JAR SHA-256 is `621008afc4f5d59357fcf06ffa644dd5aade5e091bdc363742710445f73cdaf8`. Both were obtained from services.gradle.org distribution checksums; the JAR bytes were independently retrieved from the Gradle v9.9.1 source tag. Existing wrapper locations, SDK/JDK, Flutter and dependency locks stay fixed. The verification gate rejects 9.8.1 and 9.9.0 as well as changed hosts or checksums.

The same wrapper/JAR and verification changes are prepared in Stable and Preview. Their CI and build results are recorded in the linked PRs; no Stable version bump, app promotion or publication is authorized by this tooling update. Preview retains canonical Linux plus independent Linux byte equality and full Android/upgrade/signing gates.
