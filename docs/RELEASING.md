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
7. Update the website's download section and checksums (`tools/fill-checksums.py` in `slys-web`).

## Flatpak and Flathub

The manifest packages the bundle built by CI (a "binary" Flatpak). That is fine for a `.flatpak`
file in Releases. **Flathub** requires building everything from source with no network access,
which for Flutter means vendoring the Flutter SDK, pub packages and cargo crates (the
`flatpak-flutter` tool automates it). Do that after the repository is public and the app is stable.

## Windows signing

See [SIGNING.md](SIGNING.md). Until then SmartScreen may warn; the checksum is the proof.
