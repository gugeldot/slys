# Windows code signing

Unsigned installers trigger a SmartScreen warning ("Windows protected your PC"). Signing removes
the "unknown publisher" part; reputation then builds with downloads.

Options, cheapest first:

| Option | Cost | Notes |
|---|---|---|
| **SignPath Foundation** | free for open-source projects | Needs the repo to be public and a short application. Signs from CI via `signpath/github-action-submit-signing-request`. Recommended. |
| **Azure Trusted Signing** | about 10 USD per month | Microsoft-run; individuals may be eligible depending on region. Signs from CI with `azure/trusted-signing-action`. |
| Commercial OV certificate | roughly 100-300 USD per year | Works, but the private key must live on a hardware token or cloud HSM; harder in CI. |
| EV certificate | more | No longer needed to avoid SmartScreen warnings as quickly as before; not worth it for this project. |

## Where it plugs in

In `.github/workflows/release.yml`, job `windows`:

1. sign `slys.exe` (and the DLLs) in `app/build/windows/x64/runner/Release`,
2. build the installer,
3. sign `Slys_Installer.exe`.

Secrets live in the repository's *Actions secrets*, never in the repo. Until a signing service is
configured, releases are unsigned and users should verify `SHA256SUMS`.
