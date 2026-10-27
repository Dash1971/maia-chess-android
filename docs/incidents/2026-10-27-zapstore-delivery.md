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

The release agent did not review the available 2.4.0 delivery evidence early
enough, treated public GitHub delivery as a newly discovered capability, and
retained an unnecessary requirement that the new APK also have a CDN copy.
That was a process and reasoning error. It prolonged the investigation and
encouraged a redundant large-APK upload through an older publisher.

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
