# Verify your download

Download the APK and its matching `.sha256` file from the same official GitHub
release. Verify the actual filename and checksum recorded on that release:

```sh
sha256sum -c Mobile-Maia-vVERSION.apk.sha256
apksigner verify --print-certs Mobile-Maia-vVERSION.apk
```

On macOS, use `shasum -a 256 -c` for the first command. Substitute the filenames
on the selected release; Preview asset names may differ. `apksigner` is supplied
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
