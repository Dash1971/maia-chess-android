# Zapstore delivery and false publication cache, 2026-10-27

This records the 2.5.0 investigation while Zapstore verification was still
pending. At 06:43 UTC, v2 had returned accepted/`pending` for release event
`c1d1c2d1a4db9a581ae2854915398d9ab75bb829b37214cb261b97feee273cc2`,
while the public relay and rendered listing still served 2.4.0. This is not a
claim that 2.5.0 was store-published. The [release distribution record](https://github.com/Dash1971/maia-chess-android/pull/62#issuecomment-6434116058)
tracks the subsequent outcome. The enduring, self-contained workflow is in
[RELEASING.md](../RELEASING.md#publish-the-verified-stable-apk-to-zapstore);
reading historical releases is not a routine release gate.

## The mistaken assumption

The canonical release guide failed to encode the established public GitHub
APK delivery path and required an unnecessary duplicate CDN copy. The release
agent retained that requirement and treated GitHub delivery as newly discovered.
That documentation and reasoning error prolonged the investigation and
encouraged a redundant large-APK upload through an older publisher. The normal
procedure must state the supported path directly; operators should not need to
search old release records to discover it. The 2.4.0 evidence below corroborates
that established capability, rather than adding a historical-review prerequisite.

The actual 2.4.0 asset event
`a10a6bfe234f3820a664ed1149a82bc665c4ff99d6d24a1be5da4c9c019c1005`
advertised **both** of these URLs:

- The immutable [GitHub APK](https://github.com/Dash1971/maia-chess-android/releases/download/v2.4.0/Mobile-Maia-v2.4.0.apk).
- A [Zapstore CDN copy](https://cdn.zapstore.dev/a1df8b82969ab2ad9a1045c6a094b7b2bcc3cc316369ce75754887ae9a281577).

The published [2.4.0 post-publication evidence](https://github.com/Dash1971/maia-chess-android/releases/download/v2.4.0/Mobile-Maia-v2.4.0-post-publication.zip)
contains `zapstore-relay-after.json` and `zapstore-verification.json`. They record
both URLs, valid relay signatures, the release/asset relationship, the established
publisher and certificate, and a verified **459,947,435-byte CDN download** with
SHA-256 `a1df8b82969ab2ad9a1045c6a094b7b2bcc3cc316369ce75754887ae9a281577`.
The [2.4.0 distribution record](https://github.com/Dash1971/maia-chess-android/pull/54#issuecomment-6233972011)
links that release's verification. It was not GitHub-only, and the CDN did work
then for an APK larger than 2.5.0's 455,440,608 bytes. These facts do not establish
that the service's upload policy remained unchanged on October 27.

## What failed in 2.5.0

The qualified GitHub release remained immutable: version 2.5.0 / code 82, source
`aeea49817c34f48397e910894414c1d8b0352124`, signed APK SHA-256
`22a3ada622f929104c8fb754bb9eff87a101b151f46375d446f6e82480c8b132`.
There was no need to rebuild or replace it to repair store delivery.

Several distinct failures needed separate evidence:

- A generic `failed to upload file` error was initially attributed to APK size.
  The legacy source uses that message for non-APK media. A narrowly instrumented
  error identified screenshot 5: PNG, 532,381 prepared bytes, rejected with
  HTTP 400 `upload exceeds the size limit`. A listing-only lossless WebP was
  367,074 bytes; decoded RGBA pixels and dimensions matched the qualified PNG.
  Its hash was `70e2726f4110c2750eef29ac02c7c2435078a32dae2ca9a00b5fc6fe5e945e65`.
  The source screenshot and APK were unchanged. This established the failing
  item; it did not prove an exact permanent numeric server limit.
- After the media correction, the legacy publisher separately failed uploading
  the 455,440,608-byte APK. Requiring that duplicate upload was unnecessary:
  the same qualified public GitHub APK was already available.
- A retry exited 0 without producing events because the legacy source cache
  already said 2.5.0 was published. That marker was premature, not publication
  evidence, and did not come from `publish --check`.
- App metadata had partially updated while the new release/asset was not yet
  served. Event `d459ad781bd140fd77f8572c0e1ca02d13f062c9105f7b99393532f3907fa8df`,
  created at 06:02:05 UTC, referenced the new screenshots. Calling that state
  either “nothing published” or “Zapstore complete” would have been inaccurate.

The existing Nostr identity and Android certificate were preserved. A fresh
read-only check verified the live C1 event and Android-key signatures, owner,
non-revoked state and expiry of October 12, 2027. No proof renewal or identity
change was needed.

## Why exit 0 and the cache were misleading

Pinned [zsp 0.4.17 workflow source](https://github.com/zapstore/zsp/blob/c50c1ccbf32d7fa6ae00f74990ce2c83f3bac6a1/internal/workflow/workflow.go#L202)
publishes events to relays, commits the source's version/ETag cache after those
acknowledgements, and only then uploads required blobs. A blob failure returns
without clearing that committed cache. The next fetch treats a matching cached
version or HTTP 304 as `ErrNothingToDo`; [main converts it to exit 0](https://github.com/zapstore/zsp/blob/c50c1ccbf32d7fa6ae00f74990ce2c83f3bac6a1/main.go#L212).
The read-only `--check` path does not commit this publication cache.

Recovery backed up and invalidated only the confirmed false repository marker
and ETag after checking actual relay state. It was not a reason to delete shared
caches, overwrite published events blindly or treat another successful process
exit as a completed store update.

## Corrective procedure

The canonical guide now directly specifies a reviewed current publisher,
static public GitHub `asset_url`, exact signed hash and frozen-source binding,
canonical public key/certificate checks, live C1 verification and the existing
private-signing boundary. It also specifies a conservative media delivery
budget, pixel-verified lossless derivatives, explicit media and release notes,
and actual relay/listing/download checks. It does not send future operators
through historical evidence to discover the supported path.

Reviewed [zsp 2.0.0 source](https://github.com/zapstore/zsp/tree/28bc992f0663d6bae6c40dfd1eb462c56f45cb7b)
retains a static public APK URL and [uploads an APK only without a public source](https://github.com/zapstore/zsp/blob/28bc992f0663d6bae6c40dfd1eb462c56f45cb7b/internal/release/publish.go#L301).
Its [specification](https://github.com/zapstore/zsp/blob/28bc992f0663d6bae6c40dfd1eb462c56f45cb7b/SPEC.md)
distinguishes relay acceptance from a served release. The delivery change is
avoiding a redundant upload, not inventing GitHub as an APK distribution source.

Verify whichever download URL the accepted asset actually advertises, including
redirects, against the qualified APK. If a client uses a CDN endpoint, distinguish
an actual CDN copy from a source redirect; do not require or claim automatic
caching. Report `pending` and partial publication honestly, maintain separate
GitHub/Zapstore/F-Droid status, and clean task-owned bulk after the applicable
verified downloads without waiting for this documentation PR to merge.

This documentation changes no application code, committed store config, version,
release tag, signed artifact, signing identity or release qualification result.

## Live screenshot regression and immediate recovery

At 06:02:05 UTC (15:02:05 JST), app event
`d459ad781bd140fd77f8572c0e1ca02d13f062c9105f7b99393532f3907fa8df`
replaced all eight screenshot references during the 2.5.0 attempt. All eight
URLs subsequently returned HTTP 404; the website displayed eight persistent
placeholders while its icon loaded. The current website URLs matched that
partial app event exactly. The 2.5.1 submission remained pending and did not
repair this app metadata. The evidence establishes unavailable referenced media;
it does not establish whether Zapstore discarded uploads or failed to serve them.

The release record already noted failed media verification. Recording that
failure without immediately repairing the existing listing was an operational
failure. A successful or pending release submission cannot justify degraded
metadata on an already public listing.

The previous eight screenshot URLs from the 2.4.0 metadata correction still
served valid PNGs. Recovery restores those eight verified references only,
preserving the current Markdown description, other tags and release/asset
references. These are temporarily older screenshots, not the refreshed 2.5
screenshots. New media must pass the mandatory gate before replacing them.
Compact signed before/after events, sixteen original/thumbnail GET and decode
checks, rendered verification and cleanup evidence accompany this repair PR.

The canonical release procedure now requires a saved recovery event, verified
public uploads before metadata replacement, immediate verification of every
actual image and rendered screenshot, and immediate metadata-only recovery on
failure. A combined publisher that cannot enforce that ordering must retain
working image URLs until verified replacements are ready. This rule also applies
when release publication is pending.

Counterpart review: Preview/Dev publish GitHub prereleases and do not publish
Zapstore app metadata or maintain store screenshots. Its current release guide
explicitly excludes Zapstore qualification. This Stable store-media gate has no
Preview port; no shared build, CI, verification helper or cleanup tool changed.

Recovery event `b55e139941db2a09520bc757a3a05c50b23a83e888df29a597bb8c192a7ba3bb`
was initially answered `OK true` with `pending: the listing will be saved once
its checks pass`; immediate readback still returned the broken app. The current
relay's v2 listing admission couples app promotion to a release. Replaying the
exact already stored, signed 2.4.0 release event
`36ef543171da50a9d80d839aef76a9b90906ba79bddb1aa0a13f23b4ed9b972b`
triggered promotion of the recovery app. No release event was changed or newly
signed. Subsequent signature-verified readback returned the recovery event,
with an identical release/asset event set, and all eight website screenshots
loaded with nonzero natural dimensions. Sixteen full original/thumbnail GET
and decode checks passed. Android store-client rendering was not tested.
The website still listed 2.4.0: screenshot recovery does not establish 2.5.x
store publication.

[Recovery verification and signed-event evidence](evidence/2026-10-27-zapstore-screenshot-repair/verification.json)
and [rendered listing](evidence/2026-10-27-zapstore-screenshot-repair/restored-listing.png)
are retained alongside full media checks and the before/after public event set.
[Cleanup](evidence/2026-10-27-zapstore-screenshot-repair/cleanup.json) removed the
repair binaries and temporary Go module on the signing host immediately after
verification, recovering about 23 MB; shared tools/caches and signing keys were
preserved. No APK, model or emulator output was created. The compact documentation
checkout is retained for this PR; no bulk retention is needed.

## Current screenshots restored without waiting for APK indexing

The older screenshots were an immediate recovery step, not the final result.
All eight approved current screenshots were then verified against their source
hashes at immutable raw.githubusercontent.com URLs pinned to the qualified
2.5.1 source commit `7af804d1006db12973d745c3d836e364f4810693`.
Sixteen original/thumbnail URL GET/decode/hash checks passed on both the primary
and signing hosts before changing the app metadata. This delivery path uses
already public repository images and requires no new CDN media upload.

App event `a1c9f9261d8e92d36df3a9d1abbb5e6ce34b0ce87259fb274697b0b317d33370`
now references those current screenshots. The exact existing 2.4.0 signed
release was replayed again to trigger metadata promotion. Signed readback
confirmed the intended event, unchanged description/non-image tags and an
identical release/asset event set. The website renders all eight current images
at 900 × 1920 natural dimensions. The 2.4 screenshot fallback is superseded.
See [current-media verification](evidence/2026-10-27-zapstore-screenshot-repair/latest/verification.json)
and [current rendered listing](evidence/2026-10-27-zapstore-screenshot-repair/latest/latest-listing.png).
Android store-client rendering was not tested.

The visible store release remains 2.4.0; 2.5.1 delivery is still pending. When
2.5.1 is served, the release operator must verify the visible version, actual
qualified APK download/hash/signer and this current screenshot set together
before recording store publication. No further screenshot replacement is needed
merely because APK indexing finishes. Preserve the newest verified app metadata;
do not republish the earlier failed CDN image references.

## October 29 JST: reproduce the APK-reader admission limit

The earlier investigation established a correct public URL, exact signed hash,
certificate and event references, but missed the receiver's explicit size guard.
A successful complete GitHub download does not establish that the receiving
relay will accept an APK of that size. The earlier general backlog explanation
was insufficient; no queue-stage visibility or timing measurement supported it.

Pinned public relay source `0f1ae2eabb9ed4b94bb2f42ed26799c7c0d42180`
defines `maxAPK = 300_000_000`. `keepAPK`, `tempAPK` and cached-APK checking
apply that bound. Our 2.5.1 APK is 455,440,608 bytes. We copied the unmodified
`keepAPK` function and constant into an isolated harness, fetched the actual
public GitHub URL, and reproduced `apk exceeds the size limit` after exactly
300,000,001 bytes. HTTP status was 200; the function removed its partial file.
This is a source-level reproduction, not access to the production server.

In that source, the download error propagates through `readAPKJob` to
`runAPKReader`, which schedules another fetch rather than making the size
failure an explicit permanent rejection. Direct Blossom upload separately
caps APKs at 300,000,000 bytes. Switching delivery methods does not solve
that source-level size restriction. Previously accepted 2.4.0's larger APK
is not evidence that the newer admission path accepts it.

[Upstream issue #11 now contains the reproduction and pinned source links](https://github.com/zapstore/relay/issues/11#issuecomment-6473829144),
asking the operator to confirm the deployed revision, exact error for our hash,
size support and pending-event retention. Production attribution remains
unconfirmed. No new release event or APK was submitted in response. The latest
read-only check at October 28 15:51 UTC (October 29 00:51 JST) still served 2.4.0.

[Reproduction result](evidence/2026-10-29-zapstore-size-limit/reproduction.json),
[isolated harness](evidence/2026-10-29-zapstore-size-limit/reproduce-size-limit.go)
and [cleanup](evidence/2026-10-29-zapstore-size-limit/cleanup.json) are retained.
The task-owned binary and partial download were removed immediately after
verification; no signing key was accessed. Shared Go tools and caches remain.
The canonical procedure now checks receiver limits before submission and fixes
the previous 512,000-byte image budget to below the source's 500,000-byte limit.

Preview counterpart inspected at current main: it publishes GitHub prereleases
and explicitly excludes Zapstore qualification. This service-admission guidance
has no Preview port. Shared helpers, build, CI and cleanup tooling are unchanged.

## October 29 JST: operator raises limit; original 2.5.1 events become public

At October 28 17:55 UTC (October 29 02:55 JST), the operator
[confirmed that the service now allows up to 500 MB](https://github.com/zapstore/relay/issues/11#issuecomment-6476547913)
and closed the upstream issue. The public v2 branch still showed the earlier
300,000,000-byte constant at our subsequent check. Operator policy and actual
admission therefore take precedence over treating that stale branch as the
production configuration. The isolated source reproduction did not prove the
production server's previous error or deployed revision.

A read-only check at October 28 22:36 UTC still served 2.4.0. After confirming
the qualified GitHub APK's unchanged size/hash and absence of the original
2.5.1 events, we retransmitted only the exact previously signed asset and
release events. No signer was accessed, no new event body/signature was created,
and no app-metadata event was sent. Both responses initially said pending.
By 22:38:15 UTC (October 29 07:38:15 JST), a live subscription received both
original events from the public relay:

- Asset: `032ed462cfb15128d6c06852ea9218959ee2277c40e81ad7629dd1b607eea433`.
- Release: `8a8fdafccc32d51748ade1d062bc4c6b5b5963178155664d76a919a28cfc9ede`.

BIP340 signatures and event IDs verified, and the served events matched the
original signed submission exactly. The app event remained
`a1c9f9261d8e92d36df3a9d1abbb5e6ce34b0ce87259fb274697b0b317d33370`.
The website showed 2.5.1; all eight current screenshots loaded and passed fresh
GET/decode/source-hash checks. Android store-client rendering was not tested.

A fresh full download of the asset's actual advertised GitHub URL returned
455,440,608 bytes with SHA-256
`59f730e806b6ead163714c46bf93f163309f8e6fb50295fe943112367be25f80`.
Those exact signed bytes were previously qualified with the established Android
certificate and v2/v3 signature verification. The download was streamed through
a hash without saving an APK. The subscription exited after observing both
original events; no build, model, APK or emulator output needed cleanup. Source,
tags, artifacts, signing identity and current screenshots were preserved.

**ZAPSTORE PUBLISHED** is now supported by signed relay readback, the exact public
download and the rendered listing. This changes only the Zapstore status; it
does not establish a new F-Droid catalog outcome.

[Recovery verification](evidence/2026-10-29-zapstore-recovery/verification.json),
[relay replies](evidence/2026-10-29-zapstore-recovery/retransmission.json),
[served original events](evidence/2026-10-29-zapstore-recovery/watched-readback.json)
and [rendered proof](evidence/2026-10-29-zapstore-recovery/published-listing.png)
are retained. Preview remains outside this Stable-only store workflow; no
companion port or merge applies, and shared tooling is unchanged.
