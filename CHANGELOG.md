# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

## [Unreleased]

### Changed
- Cryptography dependencies moved to their current major versions (`argon2` 0.6, `hkdf` 0.13,
  `sha2` 0.11, `rand` 0.10, `aes` 0.9, `cbc` 0.2, `cipher` 0.5, `pbkdf2` 0.13). The formats do not
  change: seeds and fragments made by 1.6.x rebuild byte for byte, and SLYS 1.x seeds still open.

## [1.6.1] - 2026-11-22

### Changed
- **New password rules, following NIST SP 800-63B and OWASP.** Minimum length is now 12 characters
  (was 10). The mandatory upper case, number and symbol are gone: they pushed people towards
  `Password1!`, while a long phrase is far stronger. The requirements are now: 12+ characters, not a
  commonly used password, strength at least Fair, and both fields equal.
- **Strength meter** under the password fields (Weak, Fair, Good, Strong). It penalises repeats,
  sequences and repeated blocks.
- **Common passwords are refused**, also when dressed with digits or symbols (`Dragon2024!`), using
  an offline list of about 220,000 entries built from SecLists (MIT). Nothing is sent anywhere.
- Rebuilding still accepts any password, so seeds made with older versions keep working.

## [1.6.0] - 2026-11-22

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
- **Redesigned and responsive.** A native window frame instead of the fake title bar, freely
  resizable. *Fragment* and *Recompose* are separate tabs that fill the window (two columns on wide
  windows, stacked on narrow ones) with an action bar at the bottom that shows the button and what is
  still missing. Changing tab slides like a carousel. The seeds are a list instead of a table.
- **Drag and drop.** Drop a file or folder from your file manager onto the Target file, Output folder
  and "Where are the pieces?" boxes instead of using Browse.
- **Better defaults.** The output folder is `<Desktop>/slys_fragments`, the same one used to look for
  the pieces when rebuilding; pieces default to 10; encryption defaults to High. Recompose always asks
  where to save the rebuilt file, and the dialog opens on the Desktop (or the folder set in Settings).
- **Password requirements** shown live: 10+ characters, upper and lower case, a number, a symbol and
  both entries equal. They turn green as they are met, and red while the cursor is in a password field.
  *Slys!* stays disabled until all are met. Rebuilding accepts any password, so old seeds still work.
- The pieces slider glides to where you click and the number counts on the way.
- **Settings:** theme and accent colour apply instantly (the app no longer quits to apply them), and
  there is a new **Inactivity wipe** card: off by default, the number of days (presets or custom, 1-3650),
  the time left, and a confirmation before turning it on. If a wipe happens, the next start says so.
- **About** shows the version, build commit, seed format and licence, with a button that copies them
  for bug reports; the tutorial is two illustrated flows; the legal notice is folded away; the host
  name is no longer displayed.
- The window has its own icon (the Flatpak ships it in 48, 64, 128 and 512 px).
- Linux: the app prefers X11/XWayland, because Flutter's Wayland path painted the UI at a quarter of
  the window on KDE Plasma with scaled monitors. `GDK_BACKEND=wayland` still forces Wayland.
- Dragging in a Flatpak accepts plain file URIs only, which avoids the portal "Invalid transfer" error.
- The Donate button opens the browser through the portal inside a Flatpak and copies the link if that fails.

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
