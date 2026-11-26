# Verify your download

Download the APK and `SHA256SUMS.txt` from the same official GitHub release.
Stable 2.6.0 and current Preview releases use that combined checksum list.
Put both files in the same folder. On Linux with GNU coreutils, run:

```sh
sha256sum --ignore-missing -c SHA256SUMS.txt
apksigner verify --print-certs APK_FILENAME.apk
```

Replace `APK_FILENAME.apk` with the downloaded name, such as
`Mobile-Maia-v2.6.0.apk`. Confirm that the checksum output names **your APK**
and says **OK**. Other assets listed in the checksum file need not be downloaded.

On macOS, run `shasum -a 256 APK_FILENAME.apk` and compare all 64 hexadecimal
characters with that APK's row in `SHA256SUMS.txt`. Then run the same `apksigner`
command. Android SDK build-tools supplies `apksigner`.

Older releases such as Stable 2.5.1 provide an APK-specific `.sha256` file instead.
For those, use `sha256sum -c APK_FILENAME.apk.sha256`, or
`shasum -a 256 -c APK_FILENAME.apk.sha256` on macOS.

A matching checksum checks the file; compare the certificate printed by
`apksigner` with the official signing fingerprint below.

The established official Stable/Preview signing certificate SHA-256 is:

```text
cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e
```

Dev uses a separate development identity. Do not treat a Dev/debug signature as
an official Stable/Preview signer. Android also checks signature continuity when
installing an update. Never uninstall the app merely to bypass a signer conflict
without first exporting important games.

## Common problems

- **Install blocked:** allow installation from the selected browser/file manager
  when Android prompts. Check Android version, free space and the selected
  channel. Do not bypass certificate/security warnings.
- **Board not found:** close other apps using the board, check power/Bluetooth,
  grant the version-appropriate nearby-device permission, and follow the
  [board guide](ELECTRONIC_BOARD_DEV.md).
- **Permission denied:** grant the requested Bluetooth permission in Android
  settings. Older Android BLE discovery also requires location permission;
  this is not location tracking. See [Privacy](../PRIVACY.md).
- **Games on another phone:** export PGNs before moving devices. A PGN transfers
  games and supported annotations, not app settings or live board/clock state.
