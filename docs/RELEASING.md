# Releasing

1. `scripts/set-version.sh 1.7.0`
2. Add the `<release version="1.7.0" date="YYYY-MM-DD">` entry to
   `packaging/flatpak/io.github.gugeldot.Slys.metainfo.xml` (newest first) and a section to
   `CHANGELOG.md`.
3. `make lint && make test`, commit, merge to `main`, wait for CI.
4. `git tag v1.7.0 && git push origin v1.7.0`
5. The **Release** workflow builds, checks that the tag matches the version, and creates a
   **draft** GitHub release with:

   | Asset | What |
   |---|---|
   | `Slys_Installer.exe` | Inno Setup installer (Windows 10+, x64) |
   | `Slys_Windows_Portable.zip` | same files, no installer |
   | `Slys.flatpak` | Flatpak bundle |
   | `Slys_Linux.zip` | portable Linux build |
   | `SHA256SUMS` | SHA-256 of every asset above |

   Every asset also gets a build provenance attestation (`gh attestation verify`).
6. Install-test the draft on a clean Windows and a clean Linux, then publish it.
7. Update the website (`site/`): version, download section and checksums (`site/tools/fill-checksums.py
   SHA256SUMS`); see `site/README.md`. Pushing to `main` publishes it with GitHub Pages.

## First release: check the pipelines without touching `main`

The workflows have never run on GitHub. Before the first real tag, run them once:

1. Push the clean history to a **new branch** (a non-destructive push: the old `main` is untouched).
2. Run **CI** and **Release** by hand (*Actions → Run workflow*, both have `workflow_dispatch`; the
   Release run builds everything and uploads artifacts but creates no GitHub release without a tag).
3. Fix what breaks (expect something on the Windows and macOS legs), then tag.

Replacing the old `main` with the clean history needs a force-push and is a separate decision.

## macOS (experimental)

Not released yet. CI has a build-only, non-blocking job to see what happens. Known gaps:

* **Sandbox vs. paths.** The runner is sandboxed (`app-sandbox`); file dialogs work through
  `files.user-selected.read-write`, but the default output folder (`~/Desktop/slys_fragments`) and a
  folder remembered from a previous run are *not* accessible without security-scoped bookmarks.
  Either implement bookmarks or ship unsandboxed with the hardened runtime.
* **Signing and notarisation** need a paid Apple Developer account; without them Gatekeeper blocks the app.
* **Packaging** (`.dmg`), an `.icns`/asset-catalog check, a universal (arm64 + x86_64) Rust library, and
  testing on a real Mac. Nobody has run the app on macOS yet.

## Flatpak and Flathub

The manifest packages the bundle built by CI (a "binary" Flatpak). That is fine for a `.flatpak`
file in Releases. **Flathub** requires building everything from source with no network access,
which for Flutter means vendoring the Flutter SDK, pub packages and cargo crates (the
`flatpak-flutter` tool automates it). Do that after the repository is public and the app is stable.

## Windows signing

See [SIGNING.md](SIGNING.md). Until then SmartScreen may warn; the checksum is the proof.
