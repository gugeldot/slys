# Security

## Reporting a vulnerability

Please do **not** open a public issue. Use GitHub's private reporting:
**Security tab → "Report a vulnerability"** on this repository. Include the version
(`slys version` or the About screen), the steps to reproduce and the impact you see. You will get
an answer as soon as possible; this is a one-person project, so please be patient.

## What SLYS protects, and from whom

SLYS splits a file into pieces and (in the default *Full* mode) encrypts every piece. To rebuild
the file you need the **seed**, the **password** and the **pieces**.

It protects against someone who gets some or all of the fragments (or the seed) but **not** the
password. It does not protect against:

* **A weak password.** Argon2id slows guessing down but cannot save "123456". Use a long
  passphrase.
* **A compromised computer** (malware, keylogger, someone watching while the file is rebuilt).
  When rebuilt, the plaintext file exists on disk again.
* **Someone who has the password and the seed.**
* **Plain and Light modes.** They leave the data (partly) unencrypted. Only *Full* is
  cryptographic protection.

## Design (summary)

* Argon2id (64 MiB, 3 passes) from the password; HKDF-SHA256 for independent keys.
* AES-256-GCM (chunked STREAM) for every fragment and the seed: tampering, reordering, truncation
  and mixing fragments of different seeds are detected.
* The seed carries a SHA-256 for each fragment and for the original; the rebuilt file is verified
  before anything is deleted.
* Full specification: [docs/FORMAT.md](docs/FORMAT.md).
* Threat model, adversarial tests, ISO/IEC 27002:2022 control mapping and the list of residual risks:
  [docs/SECURITY_ARCHITECTURE.md](docs/SECURITY_ARCHITECTURE.md).

## Known limits (please read)

* **Secure deletion is best effort.** SLYS overwrites the original (random, then zeros), flushes
  and removes it. On SSDs (wear levelling), copy-on-write or journaling file systems (btrfs, ZFS,
  APFS, some ext4 modes), snapshots and synced folders, old copies of the data may remain.
  Full-disk encryption is the only reliable protection. SLYS only deletes the original *after*
  verifying that the fragments can rebuild it; use the *Keep* option if you prefer to delete it
  yourself.
* **Memory.** The password is held in memory while an operation runs. The Rust core zeroes the keys and
  its own internal copies of the password when it is done, but the bridge request and the Flutter UI hold the typed password in a
  Dart string that cannot be reliably wiped, and the OS may swap memory to disk.
* **The saved-seeds list** (`seeds.json`) stores seeds, which are themselves encrypted, together
  with the names you give them. It is created with owner-only permissions on Unix. It does not
  hide the fact that you use SLYS.
* **The inactivity wipe** (opt-in, not enabled by default) cannot be tamper-proof. See
  [docs/INACTIVITY_WIPE.md](docs/INACTIVITY_WIPE.md).
* **SLYS 1.x seeds** use older cryptography (AES-CBC without authentication, PBKDF2 100k). They are
  supported read-only. Re-fragmenting with 1.6 or later gives you the current protection.
* **Not audited.** No independent security audit has been done. The code is public so it can be.

## Supply chain

Releases ship with `SHA256SUMS` and a build provenance attestation:

```
sha256sum -c SHA256SUMS
gh attestation verify Slys_Installer.exe --repo gugeldot/slys
```

Windows binaries are not yet code-signed (see [docs/SIGNING.md](docs/SIGNING.md)), so SmartScreen
may warn; verifying the checksum is the way to be sure you got the file we built.
