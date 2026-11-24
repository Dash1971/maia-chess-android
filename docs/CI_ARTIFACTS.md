# CI artifact retention

The checked-out channel's [Checks workflow](../.github/workflows/checks.yml) is
authoritative for artifact lifetime. Current workflows retain:

| Artifact | Retention |
| --- | ---: |
| Test/release diagnostics; Stable dependency-audit reports | 90 days |
| Unsigned Android APK | 30 days |

CI success alone does not publish an app. Retain compact hashes, source pins and
qualification evidence with the release/PR before temporary CI artifacts expire.
Clean task-owned bulk according to [Build workspace](BUILD_WORKSPACE.md); do not
keep local APK archives merely because a CI artifact will expire.
