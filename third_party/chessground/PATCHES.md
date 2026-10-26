# Mobile Maia's filtered Chessground 10.1.1 package

Upstream: https://github.com/lichess-org/flutter-chessground
Tag v10.1.1, commit 0bd34fbe720097c4a51172e2c0d8f697637eda01.

The `lib/` renderer and included artwork are byte-identical to that commit. The
manifest in `../../docs/board-style-assets.json` records their upstream Git blobs
and SHA-256 hashes. No renderer behavior or version has changed.

Local changes: `pubspec.yaml` declares only the 16 approved piece directories and
all board textures; nonessential example, tests, Swift and development files are
not vendored. Artwork notices/license texts and this explanation are added.
Unavailable enum values in upstream source are never exposed by Mobile Maia's
explicit PieceDesign allowlist. They have no corresponding bundled assets.

When updating, repeat the provenance/rights audit, preserve license notices,
update the recorded hashes, then run `python3 tool/check_board_style_assets.py`
from the app root, widget/input checks, and the APK form of the same checker.
Do not restore `assets/piece_sets/` wholesale or enumerate all PieceSet values.
