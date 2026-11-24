# Verify your download

Download the APK and checksum file from the same official GitHub release.
Stable supplies an APK `.sha256` file; Preview may use a combined `SHA256SUMS.txt`.
For a Stable APK:

```sh
sha256sum -c Mobile-Maia-vVERSION.apk.sha256
apksigner verify --print-certs Mobile-Maia-vVERSION.apk
```

For Preview's combined checksum list, compute `sha256sum APK_FILENAME.apk` and
compare the full result with that APK's row in `SHA256SUMS.txt`. The list also
includes other assets, so checking the whole list requires downloading those too.
On macOS, use `shasum -a 256 -c` for the Stable check, or
`shasum -a 256 APK_FILENAME.apk` for the Preview comparison. Substitute the
actual release filenames in the checksum and `apksigner` commands. `apksigner` is supplied
by Android SDK build-tools. A matching checksum checks the file; the signer
checks continuity with this project's official key.

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
