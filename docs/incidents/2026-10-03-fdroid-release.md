# F-Droid release recovery, 2026-10-03

This is historical context, not current F-Droid status. Recheck upstream for
every release. The enduring procedure is [RELEASING.md](../RELEASING.md).

Three distinct problems mattered during the 2.2 release:

- The 2.2.0 / 77 source contained a research ZIP rejected by F-Droid's scanner.
  Removing it in a later version did not alter version 77's immutable source.
- Version-specific Fastlane changelogs were missing from the 2.2.0 and 2.2.1
  tags, although added later to main. The listing also needed refreshing for
  the shipped features. Checking only the current working tree missed that
  distinction. Qualification now reads the exact commit/tag.
- F-Droid's existing bot request retained the failed version-77 build. A new
  version can be detected without removing an older failed block in that branch.
  Inspect the refreshed request rather than promising that a new tag heals it.

During 2.2.2 qualification, apksigner 36's default alignment rewriting also
prevented byte-identical signature reconstruction even though APK payloads and
signatures were valid. Signing with `--alignment-preserved true` fixed this.
That failure was caught before publication. Payload equality alone is not the
full reproducibility check.

Recovery used a new immutable 2.2.2 / 79 release, source
`9e0bec93b4102cf04e1405324cf323bbcf249f2b`. GitHub and an independent official
F-Droid buildserver-image build produced identical unsigned APKs. The published
signed APK passed F-Droid's developer-binary comparison and allowed-signer check.
The official update checker selected the correct new version/source. At the end
of that run, the public F-Droid catalog still showed 2.1.3 / 76 and the existing
request still had its earlier failed pipeline; GitHub publication was reported
separately from F-Droid store publication.

Evidence:

- [2.2.2 release and attached reports](https://github.com/Dash1971/maia-chess-android/releases/tag/v2.2.2)
- [Final source build and tests](https://github.com/Dash1971/maia-chess-android/actions/runs/37129448784)
- [Metadata/source recovery PR](https://github.com/Dash1971/maia-chess-android/pull/34)
- [Final release qualification record](https://github.com/Dash1971/maia-chess-android/pull/35#issuecomment-5970221044)
- [F-Droid request !50992](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/50992)

Do not hard-code these version numbers, commit IDs, or incident-era upstream
status into future release decisions. Obtain fresh evidence for each candidate.
