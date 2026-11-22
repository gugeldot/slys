# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

## [1.6.0] - unreleased

### Changed
- **One program.** The Flutter app and the Rust core are now a single application linked through
  `flutter_rust_bridge`. The separate backend executable and every `Process.start` call are gone;
  passwords no longer travel on a command line.
- **New seed format (v2)** with a checksum (CRC-32) to catch typos, an authenticated encrypted
  payload and a SHA-256 for every fragment. See `documentation/FORMAT.md`.
- **Stronger cryptography:** AES-256-GCM (chunked) instead of AES-256-CBC, Argon2id instead of
  PBKDF2 (100,000 iterations), one key derivation per operation, independent key per fragment.
- **Default encryption level is now High.** The old default (Mid) left most of the file readable.
  The setting is reset to High once on upgrade.
- Fragment names are fully random.
- The app reports progress while working and no longer freezes during key derivation.
- File dialogs use `file_selector` (works inside a Flatpak sandbox).
- The About screen shows the app version, the build commit and the seed format.

### Security hardening
- Rebuilt files and fragments are written to unguessable temporary names created exclusively
  (`O_EXCL`) and published atomically; a symlink planted at the output name is never written
  through, and "do not overwrite" no longer has a check-then-rename race.
- Windows device names (`CON`, `NUL`...) and forbidden characters coming from a seed are defused.
- Secure delete opens with `O_NOFOLLOW` and re-checks the handle.
- A seed can no longer ask for more than 512 MiB / 16 passes of Argon2 (was 1 GiB / 32).
- The decrypted seed payload is zeroised; on Linux the process is non-dumpable.
- `SLYS_FAST_KDF` only works in builds made with `--features insecure-fast-kdf`.
- Rebuilding a 1.x seed now warns that those seeds cannot be authenticated.
- Flatpak: no access to `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.kube`, password store or keyrings.
- CI: GitHub Actions pinned by commit SHA, `cargo-deny` policy (advisories, licences, no network
  crates), weekly audit, SBOM on releases, fuzz targets, an adversarial test suite.
- New `documentation/SECURITY_ARCHITECTURE.md`: threat model, controls, ISO/IEC 27002:2022 mapping,
  residual risks.

### Interface
- Changing tab slides like a carousel: opaque pages side by side, the new one pushes the old one out (no
  fade, so they never show through each other).
- The window has its own icon (and the Flatpak ships it in 48, 64, 128 and 512 px), so taskbars and docks
  that do not read the .desktop file show it too.
- Passwords need 10 characters instead of 12.
- Settings has an **Inactivity wipe** card: on/off (off by default), the number of days (presets or a
  custom value, 1-3650), the time left, and a confirmation before turning it on. If a wipe happens, the
  next start says so.
- While the cursor is in a password field, the requirements not met yet turn red (neutral otherwise);
  the "Passwords do not match" line is gone because it shifted the whole page when it appeared.
- The Donate button no longer throws inside a Flatpak: it opens the browser through the portal, and if that
  fails it copies the link and says so.
- The password has requirements that turn green as they are met (10+ characters, upper and lower
  case, a number, a symbol, both passwords equal); Slys! stays disabled until all are met. Rebuilding
  accepts any password.
- The pieces slider glides when you click the track and the number counts up or down on the way.
- Dragging files onto the app in a Flatpak: only plain file URIs are accepted, avoiding the portal
  "Invalid transfer" error.
- Fragment and Recompose fill the window: two columns with a divider on wide windows, stacked on
  narrow ones, and an action bar pinned to the bottom with the button and what is still missing.
- Icons and tutorial step markers are white with outlines instead of filled accent colour.
- Fragment and Recompose are separate tabs.
- Drag a file (or folder) from the file manager onto the Target file, Output folder and
  "Where are the pieces?" boxes instead of using Browse.
- The output folder defaults to `<Desktop>/slys_fragments` (the Desktop folder is looked up per
  language and OS); the same folder is the default for finding the pieces when rebuilding.
- Recompose always asks where to save the rebuilt file; the dialog opens on the Desktop (or the
  folder set in Settings).
- New fragmentations use 10 pieces by default (was 5); a number you saved in Settings is kept.
- About now holds the version (version, build commit, seed format, licence, with a button that copies them
  for bug reports) and is much shorter; the legal notice is folded. The version is no longer in the header.
- The tutorial is two illustrated step-by-step flows (fragment, rebuild) plus a reminder, instead of text.
- Linux: the app prefers X11/XWayland. Flutter's Wayland path painted the UI at a quarter of the window
  on KDE Plasma with scaled monitors. `GDK_BACKEND=wayland` still forces Wayland.
- Native window frame instead of the fake title bar; the layout adapts to any window size
  (two columns on wide windows, stacked on narrow ones) and the window can be resized freely.
- Theme and accent colour apply instantly (the app no longer quits to apply them).
- The Slys! button says what is missing; the seed list is a list, not a horizontal table;
  recompose options appear when a seed is selected; the host name is no longer displayed.
- Settings: default encryption now matches the rest of the app (High).

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
- Opt-in inactivity wipe of the saved-seeds list, in the core, the CLI and the app (Settings).
- Windows installer (Inno Setup) and Flatpak packaging; CI and release pipelines with checksums
  and build provenance attestations.
- Source code published under GPL-3.0-or-later.

### Compatibility
- Seeds and fragments made by SLYS 1.0 - 1.5.x can still be rebuilt (read-only support).

## [1.5.1]

Last release before the refurbish. Source in the archived history.
