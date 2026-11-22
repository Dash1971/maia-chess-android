# Gradle 9.9.2 build-security review — 20 November 2026

Pin the official Gradle 9.9.2 `-all` distribution and SHA-256 in the Android
wrapper and offline verification gate. The existing regression suite rejects
former vulnerable pins, changed download hosts and incorrect checksums.

The [9.9.2 release notes](https://docs.gradle.org/9.9.2/release-notes.html)
address four advisories published 19 November:

- [Daemon registry creation permissions](https://github.com/gradle/gradle/security/advisories/GHSA-35pj-rg5r-8rpv): another local user can retain a readable registry handle and obtain daemon authentication tokens. Shared Linux/macOS build hosts make this relevant.
- [TestKit temporary-directory ownership](https://github.com/gradle/gradle/security/advisories/GHSA-99wf-vhq9-wm2x): a pre-created default TestKit directory can supply build configuration/code. The patch also covers plugin tooling that may use TestKit.
- [Transitive snapshot dependency verification](https://github.com/gradle/gradle/security/advisories/GHSA-7f7r-77ff-fr6f): transitive changing modules could evade verification. Retain reviewed dependency locks and upgrade the resolver.
- [SFTP host-key verification](https://github.com/gradle/gradle/security/advisories/GHSA-4mf6-7pm2-6wm8): this app uses HTTPS repositories; the distribution upgrade still incorporates the fix.

The patch includes the earlier 9.9.1 security fixes. Java 17 remains supported;
Flutter, AGP, Kotlin, Pub locks, models, signing identities and channel gates
remain pinned. Preview and Stable receive the same wrapper/security-gate changes
and keep their channel-specific CI/release requirements. Stable app promotion
and publication remain separate.

Official distribution checksum source:
<https://services.gradle.org/distributions/gradle-9.9.2-all.zip.sha256>.
SHA-256: `1ac85e9cbc2b091ad04e6c6d0f486f0a2a2fabd78f9f8719a0d5bcc0ce1b345b`.

Both repositories passed 12 workspace-helper and six security-pin checks locally.
Their PR checks and Preview's exact-source Linux/native release qualification
record integration and build results. No Stable APK publication is authorized
by this tooling update.
