# Stable 2.6 documentation preparation — 25 November 2026

Prepared on draft [#82](https://github.com/Dash1971/maia-chess-android/pull/82),
including the app behavior shipped in Preview beta.13. Stable 2.5.1 remains
published; this is not release approval or exact-source APK qualification.
No application builds, GitHub Actions or LFS downloads were performed.

## Documentation review outcomes

- [#87](https://github.com/Dash1971/maia-chess-android/issues/87): factual repairs
  already landed on this draft through #90. Current pins, browser offline use,
  shipped features, passed board acceptance, localization scope, CI retention,
  R8 adoption and crash recovery are described correctly. Superseded Gradle #73
  is closed; the website Stockfish wording was fixed through its #5. The older
  F-Droid readiness record now lives in history with a forwarding root page.
- [#88](https://github.com/Dash1971/maia-chess-android/issues/88): #90 supplies the
  docs/release indexes, contributor/templates, security/privacy pages,
  architecture map, pinned model-export pointer, notices, download verification
  and troubleshooting. Private vulnerability reporting is enabled. Repository
  homepage now points to mobilemaia.org; relevant Android/chess/Flutter/offline
  topics are set. Source pages remain unpublished to Stable main until #82 merges.
- [#89](https://github.com/Dash1971/maia-chess-android/issues/89): README detail
  moves to [the user guide](../USER_GUIDE.md). Defaults have one table; sampling
  research links to its authoritative report; Settings guidance is in Settings;
  repeated credits stay in README. Outdated illustrative screenshots are removed
  from the guide, with only Recent games and the relevant export menus recaptured.
  Existing public README fragments forward to their new sections, including the
  website's installation, board and availability links.

The mandatory [Zapstore procedure](../ZAPSTORE_PUBLISHING.md) is extracted from
RELEASING without removing gates, recovery instructions or verification scope.
RELEASING keeps its public heading and links to the full procedure. Channel
publication history is moved into [history](../history/channel-publication-records.md);
BUILD_CHANNELS keeps current policy and forwarding fragments. AGENTS points to
authoritative procedures rather than restating the full process. Shared workspace,
operator helpers and channel-specific qualification behavior are unchanged.

Localization guidance and historical language reviews are grouped under
[l10n](../l10n/README.md). Ambiguous 2.1.0-beta verification records now have full
versioned filenames in verification. Electronic-board continuation uses the
consistent ELECTRONIC_BOARD prefix. Original paths retain forwarding links and
fragments. Historical claims and recorded outcomes are unchanged; relative links
are rebased mechanically. Existing release-notes paths remain stable to preserve
release links, with the existing release index as their entry point.

67 unreferenced historical screenshot assets (4,795,858 bytes) were removed from
current source after checking repository references, current website index/about
sources and store references. The read-only Zapstore app event
`a1c9f9261d8e92d36df3a9d1abbb5e6ce34b0ce87259fb274697b0b317d33370`
uses eight images pinned to commit `7af804d1006db12973d745c3d836e364f4810693`
under Fastlane, not the removed docs assets. Current Fastlane files remain;
published Git history and pinned store URLs are untouched. No store event was
published. Older referenced examples and their provenance remain available.

## Validation and counterpart assessment

- Full Stable host suite: **1,611 passed, 1 skipped**; analyzer clean.
- Final release-verification Python suite, including the two new doc checks: **184 passed**.
- Localization/terminology: **474 messages in ten catalogs**, passed.
- Added Stable documentation link/fragment checks cover moved guide/procedure
  links and the public website's README anchors; metadata/source checks also run.
- The promoted PGN analysis implementation and both regression suites match
  Preview #267; Stable retains its branding, package, blue icon, 79M model,
  version 2.6.0+84, signer configuration, ABIs and dependency lockfile.
- Preview #267 is merged and beta.13 published; Stable #82 remains a draft.
  The #87/#88 documentation companion, Preview #277, is already merged. This
  remaining restructure concerns Stable-owned README/manual/Zapstore/history,
  so it does not replace Preview's independent guide or release procedure.
  The new link test targets this Stable document layout. The RELEASE_CHECKS edits
  remove an obsolete Stable upgrade version and point to Stable's authoritative
  workflow dispatch; Preview has its own release procedure, so no port applies. Shared mechanics are
  not changed and need no new counterpart port.

[Capture provenance](../screenshots/20261125_v0_shared_2_6_provenance.md) records
the actual Preview APK, unbranded shared views and controlled fixtures. The task
emulator process, downloaded APK and AVD were removed after retaining the images;
remote free space increased from 149021331456 to 150853849088 bytes. Local host
intermediates and temporary test environment are retired after final checks,
with compact evidence retained. Shared SDKs, caches, keys and unrelated work stay.

Final testing approval, source freeze and all exact-source Stable release gates
remain pending under [RELEASING](../RELEASING.md).
