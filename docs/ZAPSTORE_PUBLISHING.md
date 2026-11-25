# Zapstore publication

This is the mandatory Stable Zapstore step of [the release procedure](RELEASING.md#4-stage-publish-and-verify-the-public-download).
A request only to prepare a PR or build an APK does not authorize publication.

### Publish the verified Stable APK to Zapstore

Zapstore is a separate developer-published channel. The committed
[`zapstore.yaml`](../zapstore.yaml) selects Stable GitHub tags and their one
universal `Mobile-Maia-v<version>.apk` asset; it does **not** watch GitHub or
publish updates by itself. The F-Droid bot does not publish to Zapstore either.

**Description format:** F-Droid's `full_description.txt` contains HTML; the
Zapstore Android client renders Markdown. Its website can render HTML, so a
successful website check alone can miss literal `<b>`, `<ul>` and `<li>` tags
on Android. Keep an explicit Markdown `description` in `zapstore.yaml`; YAML
metadata takes precedence over the publisher's automatic Fastlane import.
Preserve the same wording, with Markdown bold headings, blank lines and bullets.
Using the Python environment from [release section 3](RELEASING.md#3-sign-the-verified-artifact-and-run-the-combined-gate), run:

```sh
python tool/check_zapstore_metadata.py
# When the Fastlane copy changes, generate the matching Markdown to review
# and place under description: | in zapstore.yaml:
python tool/check_zapstore_metadata.py --print-description
```

CI runs this check and its regression cases using the existing release-tools
environment. It rejects missing descriptions, HTML (including escaped tags)
and drift from the F-Droid wording. New HTML constructs require a reviewed
conversion. Check the published app-metadata event's actual content as well
as its rendering: paragraphs, bold headings and list spacing must remain clear
in the Android Markdown renderer. Record whether the Android store client was
actually tested; do not describe a website-only check as Android validation.

A correction only to an existing store listing is not a new APK release.
For such a correction, publish only the replacement app-metadata event with
the established identity, after verifying the current event and intended diff.
Preserve its other metadata and the existing release/asset events; verify the
accepted content and unchanged APK references afterward. Do not overwrite a
release, rebuild, move its tag, or rerun the full APK-release process just to
repair listing text. Record the correction and evidence on GitHub.

## Publisher, identity and qualified input

Use the qualified public GitHub APK as the release source. A second APK upload
to Zapstore's CDN is **not** a publication requirement. Keep the same immutable
GitHub release, tag and APK throughout this step; a store-delivery failure does
not justify rebuilding or replacing them.

The reviewed publisher is **zsp 2.0.0**, source commit
`28bc992f0663d6bae6c40dfd1eb462c56f45cb7b`. Pin and record the executable's hash,
architecture and version; verify `--version` and command help before use.
Review a later publisher before changing this pin. The v2 release provides a
Mac ARM64 binary but no Intel Mac binary; an Intel signing host can compile the
pinned source with Go 1.27.3 (declared by that source) and Clang. Reuse shared
tools and caches, prevent an unbudgeted toolchain download, keep tool
source/output under task ownership, and obey the disk budget.
This tool preparation never rebuilds the application APK. Pinned references:
[zsp release](https://github.com/zapstore/zsp/releases/tag/v2.0.0),
[configuration and CLI specification](https://github.com/zapstore/zsp/blob/28bc992f0663d6bae6c40dfd1eb462c56f45cb7b/SPEC.md),
[public-source APK upload guard](https://github.com/zapstore/zsp/blob/28bc992f0663d6bae6c40dfd1eb462c56f45cb7b/internal/release/publish.go#L301).

Check these established Stable identities directly; do not infer the actual
signer from a YAML field or a previous command's exit status:

| Identity | Required value |
| --- | --- |
| Android package | `com.dash1971.maia_chess` |
| Nostr public key, hex | `6d422f13061d8252cddb028c50aa93d347c74775da8e4b724c1d2a2d8f03fac8` |
| Nostr public key, npub | `npub1d4pz7ycxrkp99nwmq2x9p25n6druw3m4m28ykujvr54zmrcrltyqwnjah2` |
| Android certificate SHA-256 | `cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e` |

On the existing signing host, derive only the public key from the configured
signer and compare it with this table. Keep the Nostr private key, Android
keystore and passwords on that host, outside disposable bulk. Supply signing
through the established local runner or remote signer; never put secrets in
source, GitHub Actions secrets, command arguments, logs or release evidence.
In v2, YAML `pubkey` is accepted but ignored; `SIGN_WITH` and the active NIP-C1
proof determine authorization. Query the live kind-30509 proof for the APK
certificate: verify its event signature, Android-key proof signature, owner or
authorized delegate, expiry and non-revoked state. Reuse a valid proof; ordinary
publication does not require creating or renewing it. Do not rotate identities
or introduce a delegate to work around a failed check.

## Check service admission limits before submission

A public GitHub URL avoids a duplicate APK upload; it does **not** avoid the
relay downloading and checking the APK. Compare the qualified APK's exact byte
size with the current receiver's admission limits, independently of local zsp
preflight and successful GitHub download checks. Record dated source/operator
evidence and distinguish public source behavior from confirmed deployed policy.

**Current announced APK limit: 500 MB.** The operator
[confirmed this limit on October 28, 2026 UTC](https://github.com/zapstore/relay/issues/11#issuecomment-6476547913).
Use **500,000,000 bytes (decimal 500 MB)** as our conservative publishing budget;
the announcement did not specify a byte-level configuration, so confirm current
service policy for a file near that boundary. GitHub-hosted APKs still pass the
receiver's download/verification path; a public URL does not waive its limits.
Stable 2.5.1 is **455,440,608 bytes** and was subsequently admitted after one
retransmission of its exact original signed asset and release events. The
unchanged events became publicly served, and the rendered listing showed 2.5.1.
This is dated operator/admission evidence, not a permanent guarantee.

Earlier public v2 commit `0f1ae2eabb9ed4b94bb2f42ed26799c7c0d42180`
has a 300,000,000-byte reader/upload limit. Its unmodified download function
reproduced a size rejection for our actual GitHub APK. That isolated result
identified a receiver-side compatibility risk but did not establish the running
server's revision or logs. Do not use a stale source constant to contradict
newer confirmed operator policy and actual admission. See the
[diagnostics](https://github.com/zapstore/relay/issues/11#issuecomment-6473829144)
and [verified recovery record](incidents/2026-10-27-zapstore-delivery.md).

If the qualified APK exceeds a known admission limit, treat Zapstore delivery as
unresolved before sending new events. Obtain a supported server-side resolution;
do not assume URL delivery, retries, or a previous larger published APK bypass
the current limit. Preserve the qualified source, APK, models, hash and identity.
Do not rebuild, reduce the model, switch delivery methods blindly or generate
new release events merely to work around an unconfirmed service limit.
After a service correction, check whether the original events remain queued
or have expired before deciding whether exact-event retransmission is needed.

`pending` is the response at a particular time, not a durable status dashboard.
A later public-query absence proves only that the release is not served. Do not
claim it remains queued without current evidence. Retain the full response and
exact event IDs; use the existing upstream issue for concrete backend findings.
For general publishing questions, maintainers direct users to the
[Zapstore forum](https://zapstore.dev/community/forum); inspect current routing
guidance before creating another report. Do not duplicate an existing issue.

## Task config, notes and media

Copy the qualified source's `zapstore.yaml` into the task's owned bulk directory.
Preserve its approved Markdown and app metadata. Set the exact already-verified
public APK URL with this **mapping**, substituting the qualified version:

```yaml
release_source:
  asset_url: https://github.com/Dash1971/maia-chess-android/releases/download/v<VERSION>/Mobile-Maia-v<VERSION>.apk
release_notes: ./release-notes.md
icon: ./media/icon.png
images:
  - ./media/1.png
  - ./media/2.png
  # Continue with the actual approved images, in display order.
```

The `asset_url` mapping selects a static public download. A bare GitHub APK URL
can instead be detected as a forge repository URL. Remove redundant
`release_filter` and `match` entries from this task copy: the exact URL and
`--apk-hash` bind the candidate. Keep the approved release notes and all named
media inside the task config's directory, using fixed copies from the qualified
source. Do not leave screenshots to a later `main` checkout or Fastlane lookup.
This task copy does not change the committed config, frozen source or APK.

Keep uploaded images **below 500,000 bytes each** for the current service.
The investigated v2 source uses 500,000 bytes, not 500 KiB (512,000 bytes).
This dated source limit is not proof of permanently deployed policy:
record an actual rejection and current policy rather than guessing from a
large APK's size. Optimize losslessly first. If needed, prepare a listing-only
lossless WebP derivative and verify identical decoded RGBA pixels and dimensions
against the qualified PNG. Retain source/output hashes, byte counts and that
comparison; keep the original repository screenshot and APK unchanged. Use
`--no-compress` when publishing these reviewed files: v2 otherwise re-encodes
raster images. A generic upload error is not enough to choose a file to alter;
identify the failed media's hash, size and MIME type first.

## Mandatory media gate and failure recovery

App metadata is independently replaceable: publishing it can break the existing
listing even when the new release fails or remains pending. A release failure
must never leave the current listing pointing at unavailable screenshots.

Before any command that can replace app metadata:

1. Save the current signed app event, its ordered icon/image URLs, and the
   current release/asset IDs. Prepare a reviewed metadata-only recovery event
   preserving the description and all unrelated tags. Keep this compact
   recovery evidence outside disposable bulk.
2. Upload new media before publishing references to it. GET **every exact public
   icon/screenshot URL**, follow redirects, require HTTP 200 and successfully
   decode the complete image with nonzero dimensions. Verify served image
   hashes against the reviewed delivery files. Check website thumbnail URLs
   separately (currently `?class=thumbsm`). An upload receipt, HEAD, hash in a
   URL, publisher exit status or `pending` result cannot pass this gate.
3. If the publisher cannot expose and verify uploaded URLs before replacing
   metadata, do not use that combined path with unverified new images. Retain
   the previous verified image URLs until a separate verified upload is ready.
   Preserve the approved current description. Do not repeatedly publish a full
   release to repair media.
4. Immediately read back the accepted signed app event and repeat GET/decode
   checks for **all actual icon/image references**. Inspect the rendered website
   and confirm every screenshot displays; placeholders are a failure. Save URL,
   status, decoded dimensions, bytes/hash, event IDs and a rendered capture.
5. On any media failure, restore the previously verified image references
   immediately with a newer app-metadata-only event under the established
   identity. Re-read current state before signing; abort on an unexpected
   concurrent edit. Preserve current description, unrelated tags and existing
   release/asset events. Verify the restoration by signed relay readback,
   complete image GET/decode checks and the rendered listing. Do not leave a
   broken live listing while awaiting release indexing or a documentation PR.

Read the relay's full `OK` response text. An `OK` boolean of true with a
`pending:` message means buffered, not publicly stored. A metadata-only recovery
can also be buffered behind pending releases. If signed readback still returns
the broken app, investigate the relay's listing admission rules. In the October
27 recovery, replaying the **exact existing signed and stored release event**
(same event ID and bytes, no new signature or modified fields) allowed the
recovery app event to be promoted against that admitted release. Verify the
stored release/asset set remains identical afterward. This is a targeted
recovery trigger, not permission to create duplicate release events, delete
pending releases or overwrite a published release.

Verified immutable public image URLs are also supported. If the CDN upload or
promotion path is unavailable, use the approved screenshots at URLs pinned to
the exact qualified source commit (for example raw.githubusercontent.com with
a full commit SHA), provided all original and website image requests pass the
same GET/decode/hash gate. Do not use a moving branch URL. Record the hosting
choice and source commit; switch to those verified current images without
waiting for APK indexing. Screenshot metadata and release indexing are separate.
A temporary fallback to older screenshots is not completion of current-release
media maintenance: replace it promptly with verified current screenshots and
include them in the intended version's final rendered store check.

Recover the listing before reporting a pending store handoff. Report temporary
use of older screenshots explicitly and replace them only after the new media
passes this same gate. Pending release events and listing health are separate
checks. Never mark media verified because the version, icon or description alone
loads. No APK rebuild, tag replacement or full release qualification is needed
for this scoped listing repair.

## Check, publish and verify

Set `version`, `version_code`, `release_sha` and `apk_sha256` from the completed
qualification and public GitHub download checks. `release_sha` must be the full
frozen commit, and `apk_sha256` the **signed** APK hash. Record its size and
approved certificate too. On the signing host, set the public infrastructure
variables `RELAYS=wss://relay.zapstore.dev` and
`BLOSSOM_URL=https://cdn.zapstore.dev`. Set `TMPDIR` to an existing directory
inside owned bulk so temporary APK downloads remain covered by cleanup.
With `zsp` resolving to the pinned executable and `config` to the task copy:

```sh
zsp check --json --apk-hash "$apk_sha256" "$config"
zsp publish --json -q --no-compress --apk-hash "$apk_sha256" \
  --commit "$release_sha" "$config"
```

The first command is read-only preflight; inspect the actual package, version,
code, signed hash, certificate, live proof, authorized public key and existing
published version before proceeding. Stop on a mismatch. The second command
signs and sends public events. Stable publication authorization covers it;
do not ask again unless the user excluded Zapstore or a new decision falls
outside that scope. Do not add `--overwrite-release` merely to get past a
version guard. Omit `--app-created-at-release` so a corrected app-metadata event
receives a fresh timestamp. Check the final selected APK again if the source
or publishing invocation changes.

The public-source path publishes the verified GitHub URL without uploading a
duplicate APK. A publisher may still upload icons/screenshots. Treat JSON
`pending` as pending and preserve its event ID/status. Perform a bounded
read-only relay/listing check, then record the owner, next action and follow-up
time if it remains pending. Do not publish a duplicate or retry indefinitely
while waiting for indexing. Pending alone does not require retaining bulk;
retain compact evidence and clean after the applicable public-download checks.
Exit 0, a local cache marker or relay acceptance alone is not store publication.
Legacy zsp 0.4.17 committed
its source cache before blob uploads; after a failed upload it could silently
skip a retry with exit 0. If investigating that failure, back up and invalidate
only the confirmed false repository cache entry after checking actual upstream
state; never delete unrelated caches or overwrite a release blindly. Record
partial app-metadata publication separately from release/asset publication.

## Recover a pending submission

Retain the original **complete signed public event JSON**, not only the event
IDs or a publisher success summary, with compact release evidence outside bulk.
Use a reviewed publisher capture/export path; do not assume the CLI summary
contains the signed objects. Never include private keys in this evidence.

1. Query the original asset/release IDs and current app event read-only. Record
   the time and verify any returned event IDs/signatures. If the intended
   release is already served, continue with publication verification below;
   do not submit it again. Public absence does not establish that it remains
   queued: a prior `pending` reply can outlive failure or expiry.
2. Inspect the full relay reply and identify the unresolved check. Compare the
   exact qualified APK's size, URL, hash, certificate and active C1 proof with
   current service requirements. Preserve the working app metadata. If a
   service change is needed, obtain the operator's correction before retrying;
   repeated submissions do not repair a receiver rejection.
3. After the correction, recheck that the intended release is still absent and
   that the qualified GitHub APK and publisher identity are unchanged. Using
   the original complete signed objects, retransmit the **asset first, then
   the release**, once, to the established relay. The Nostr messages are:

   ```text
   ["EVENT", <original signed kind-3063 asset object>]
   ["EVENT", <original signed kind-30063 release object>]
   ```

   Preserve their IDs, signatures, timestamps, tags and content exactly. Do not
   send the older app event: it can replace repaired text or screenshot URLs.
   This targeted retransmission needs no APK rebuild, signing-key access,
   new signature, version bump or `--overwrite-release`. If the original signed
   objects are unavailable, stop this exact-event recovery path and review the
   publisher's supported recovery procedure; do not invent replacement events.
4. Save both complete acknowledgements, including error or `pending:` text.
   After acceptance, subscribe/query read-only for up to five minutes; record
   the observation window. This is our bounded follow-up window, not a service
   guarantee. If still absent, record the exact replies, owner and next check
   time, and request the operator's processing/error status through the existing
   issue when authorized. Do not loop over publication or report success.
5. Once publicly served, verify the original signed asset/release objects,
   their relationship to the intended app/version and the preserved current
   app metadata. Complete **all publication checks below**: full GET of the
   actual advertised APK URL, qualified hash/size/signer, rendered intended
   version and every current screenshot. State whether Android or only the
   website was tested. Update the existing release distribution record; keep
   F-Droid's independently dated status separate. Clean task-owned bulk after
   retaining compact evidence, without waiting for documentation to merge.

For 2.5.1, retransmitting its original signed asset/release after the operator's
500 MB correction succeeded with the **same event IDs**. It is a recovery of the
same submission, not permission to create a duplicate release or blindly rerun
the full publisher with an old media configuration.

## Required publication evidence

Before recording `ZAPSTORE PUBLISHED`, retain all of the following:

- The actual relay, publishing public key and app/release/asset event IDs;
  valid signatures, package/version/code, full source commit, signed APK hash,
  size and certificate, and the release's references to its app and asset.
- The asset's **actual advertised download URL** and any redirects. Download it
  and verify the qualified hash, size and Android signer. The public GitHub URL
  is a supported delivery path; no duplicate CDN copy is required. If a CDN URL
  is advertised or used by the client, check its actual GET behavior separately
  and distinguish a cached copy from a redirect to GitHub. Do not claim automatic
  CDN caching. HEAD can differ from the service's GET redirect fallback.
- The client-rendered [Mobile Maia listing](https://zapstore.dev/apps/com.dash1971.maia_chess)
  showing the intended release and working media/download; inspect the published
  Markdown content too. Raw page HTML does not establish this client-side state.
  Record whether an Android store client was tested or only the website.

Keep GitHub, Zapstore and F-Droid outcomes separate. On failure, retain the exact
stage, safe diagnostic context and next action; keep the immutable GitHub release
intact. The [2026-10-27 incident](incidents/2026-10-27-zapstore-delivery.md) explains
the older assumptions and cache failure; the workflow above is self-contained
and does not require researching historical releases.

No Zapstore auto-publisher is currently deployed. A future local post-release
job must run only after the qualified GitHub release and its public APK have
passed the checks above, use the existing local Nostr signing boundary, avoid
duplicate version publication, verify relay, listing and actual download
results, and alert on failure. Do not make a GitHub tag or `zapstore.yaml` change alone a trigger
that can publish an unqualified APK.
