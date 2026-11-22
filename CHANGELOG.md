# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

## [1.6.0] - unreleased

### Changed
- **One program.** The Flutter app and the Rust core are now a single application linked through
  `flutter_rust_bridge`. The separate backend executable and every `Process.start` call are gone;
  passwords no longer travel on a command line.
- **New seed format (v2)** with a checksum (CRC-32) to catch typos, an authenticated encrypted
  payload and a SHA-256 for every fragment. See `docs/FORMAT.md`.
- **Stronger cryptography:** AES-256-GCM (chunked) instead of AES-256-CBC, Argon2id instead of
  PBKDF2 (100,000 iterations), one key derivation per operation, independent key per fragment.
- **Default encryption level is now High.** The old default (Mid) left most of the file readable.
  The setting is reset to High once on upgrade.
- Fragment names are fully random.
- The app reports progress while working and no longer freezes during key derivation.
- File dialogs use `file_selector` (works inside a Flatpak sandbox).
- The About screen shows the app version, the build commit and the seed format.

### Fixed
- A failed decryption while rebuilding used to write the encrypted bytes as if they were the file
  and then delete the fragments. It is now an error and nothing is deleted.
- The original file was deleted without checking that the fragments could rebuild it. It is now
  verified byte for byte first.
- Output files are written atomically and never overwrite an existing file unless asked.
- Names inside a seed are validated (no path traversal).

### Added
- `slys` command line tool for testing and scripting.
- Best-effort secure deletion of the original and of consumed fragments.
- Opt-in inactivity wipe of the saved-seeds list in the core and CLI (not in the UI yet).
- Windows installer (Inno Setup) and Flatpak packaging; CI and release pipelines with checksums
  and build provenance attestations.
- Source code published under GPL-3.0-or-later.

### Compatibility
- Seeds and fragments made by SLYS 1.0 - 1.5.x can still be rebuilt (read-only support).

## [1.5.1]

Last release before the refurbish. Source in the archived history.
