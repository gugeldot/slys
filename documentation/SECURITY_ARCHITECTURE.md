# Security architecture

How SLYS is designed, built and tested to be hard to attack, and how that maps to
ISO/IEC 27002:2022 (the controls of ISO/IEC 27001:2022 Annex A).

> **What this document is not.** ISO 27001 certifies an *organisation's management system*, not a
> program, and nobody can be "compliant" by writing code. What a software project *can* do is
> implement the technical controls an auditor would ask about (secure development, cryptography,
> vulnerability and supply-chain management, testing) and keep evidence of them. That is what this
> page maps. Items that need a person or an organisation to act are listed as **owner action**.
> SLYS has not had an independent security audit.

Related: [FORMAT.md](FORMAT.md) (file formats, Kerckhoffs analysis),
[INACTIVITY_WIPE.md](INACTIVITY_WIPE.md), [../SECURITY.md](../SECURITY.md) (reporting, limits),
[RELEASING.md](RELEASING.md), [SIGNING.md](SIGNING.md).

---

## 1. Security requirements (ISO 27002 8.26)

| ID | Requirement |
|---|---|
| SR-1 | Without the password, fragments and seed reveal neither content nor the file's name, size or fragment names. Only the password is secret (Kerckhoffs). |
| SR-2 | Any modification, reordering, truncation, loss, or mixing of fragments is detected. A wrong file is never produced silently. |
| SR-3 | Nothing is deleted before the rebuilt result has been verified byte for byte. |
| SR-4 | A hostile seed or fragment (e.g. received from someone else) must not be able to write outside the chosen folder, overwrite other files, crash the program, or exhaust memory/CPU. |
| SR-5 | The program never uses the network and sends no telemetry. |
| SR-6 | Secrets are kept in memory only as long as needed and wiped afterwards; they never reach logs, command lines or crash dumps. |
| SR-7 | No switch in a release build weakens cryptography. |
| SR-8 | Every release is reproducible from a tag, checksummed and attested; dependencies are pinned and policed. |

## 2. Assets, actors, trust boundaries

**Assets:** the user's file (confidentiality, integrity), the password, the seed, the fragments,
the local seed list (`seeds.json`).

**Actors:** (A) someone who obtains the fragments only; (B) someone who obtains fragments + seed
but not the password (offline guessing); (C) someone who can modify files in the fragments or
output folder (tamper, symlink and race attacks); (D) someone who *sends* the user a seed or
fragments (hostile input); (E) a local process of the same user (memory/debugger snooping);
(F) a supply-chain attacker (dependency, CI action, release artefact); (G) someone who steals the
whole unlocked computer (out of scope, see §6).

```
 user ──password──▶ [Flutter UI (Dart)] ──FFI──▶ [slys-core (Rust)] ──▶ disk: fragments, seeds.json
                     no crypto, no parsing        all crypto, parsing,       (trust boundary: anything
                     of untrusted data            validation, deletion        on disk can be tampered)
 seed text ◀──paste──▶ (untrusted input crosses into slys-core, which treats it as hostile)
```

Design consequences: the UI holds no cryptography and never parses seeds or fragments; every
untrusted byte is handled by memory-safe Rust code; the only wire between them is a narrow API
(`crates/slys-bridge/src/api`).

## 3. Threat model (STRIDE) and controls

| Threat | Example | Control | Evidence |
|---|---|---|---|
| **S**poofing | Fragments from another seed slipped in | Per-fragment key derived from `seed_id` + index, `seed_id`/index in AEAD associated data, SHA-256 of every fragment inside the encrypted seed | `fragments_of_another_seed_do_not_mix`, `swapped_and_missing_fragments_are_detected` |
| **T**ampering | Flip one bit in a fragment or in the seed | AES-256-GCM (STREAM) per 64 KiB chunk + SHA-256 + AEAD over the seed with its header as AAD. CRC-32 on the seed text is only a typo check | `flipping_any_bit_of_any_fragment_is_detected_in_every_mode`, `flipping_any_byte_of_the_seed_is_rejected_even_when_the_crc_is_fixed_up` |
| **T**ampering | Truncate / extend a fragment or seed | Chunk "last" flag, exact size and hash check | `truncating_or_extending_a_fragment_is_detected`, `every_truncation_of_a_seed_is_an_error_and_never_a_panic` |
| **R**epudiation | n/a (no accounts, no server) | — | — |
| **I**nformation disclosure | Fragments of a *Full* file | Encrypted + authenticated; random file names; sizes only roughly reveal the file size | `full_mode_leaves_nothing_readable_but_plain_does` |
| **I**nformation disclosure | Offline password guessing against the seed | Argon2id (64 MiB, t=3) so each guess is expensive; parameters stored in the seed so they can be raised. A weak password is still weak | `documentation/FORMAT.md` §2 |
| **I**nformation disclosure | Secrets left in memory / dumps | `Zeroizing` keys and passwords, decrypted seed payload zeroised, process made non-dumpable on Linux (no core dumps, no same-user ptrace) | `hardening.rs`, `marks_process_non_dumpable` |
| **I**nformation disclosure | Password on the command line / shell history | CLI refuses passwords in argv (prompt, `--password-stdin`, or env) | `crates/slys-cli` |
| **D**enial of service | Seed asking for 4 TiB of Argon2 memory | Parameters bounded when *reading* a seed: m ≤ 512 MiB, t ≤ 16, lanes ≤ 16; ciphertext ≤ 16 MiB; ≤ 10 000 fragments; rejected before any KDF work | `hostile_kdf_parameters_are_refused_without_doing_the_work` |
| **D**enial of service | Garbage / malformed input | Parsers return errors, never panic; `#![deny(unsafe_code)]` in the core | `garbage_input_never_panics`, fuzz targets (§5) |
| **E**levation / write primitive | Planted symlink at the output name or temp name | Temp files have unguessable names and are created with `O_EXCL` (`create_new`); no-overwrite uses an atomic hard link, not check-then-rename; dangling symlinks count as "exists"; overwrite replaces the link itself, never writes through it | `recompose_never_writes_through_a_symlink_at_the_output_name`, `dangling_symlink_at_the_output_name_counts_as_existing`, `publish_refuses_to_replace_unless_told` |
| **E**levation / write primitive | Path traversal in names inside a seed (`../../x`) | Names validated when the seed is opened (no `/`, `\`, NUL, `.`, `..`) | `unsafe_names_rejected` |
| **E**levation / write primitive | Windows device names / alternate streams from a hostile seed (`CON`, `a:b`) | Name sanitiser: reserved names defused, `:` and other forbidden characters replaced, trailing dots/spaces trimmed | `windows_device_and_odd_names_are_defused` |
| **E**levation / data loss | Secure-delete follows a symlink and shreds something else | `symlink_metadata` check, `O_NOFOLLOW` open, regular-file re-check on the opened handle | `secure_delete_does_not_touch_what_a_symlink_points_to` |
| Data loss (self-inflicted) | Wrong password deletes your fragments (this was the 1.x bug) | Verify-before-delete (SR-3); a failure leaves everything in place and writes no output | `wrong_password_does_not_write_anything`, `originals_and_fragments_are_removed_only_on_success` |
| Downgrade | Environment variable weakens the KDF | `SLYS_FAST_KDF` is compiled in only with `--features insecure-fast-kdf`; release builds ignore it | `crates/slys-cli/src/main.rs` |
| Supply chain | Malicious / vulnerable dependency, hijacked CI action | `Cargo.lock` committed; `cargo-deny` (advisories, licences, bans, sources) on every push and weekly; no network crates allowed; GitHub Actions pinned to commit SHAs with `persist-credentials: false`; Dependabot; SBOM and provenance attestation on releases | `deny.toml`, `.github/workflows/` |

## 4. Principles applied (ISO 27002 8.27, 8.28)

* **Memory safety:** all parsing and cryptography is Rust. `unsafe` is denied crate-wide and allowed
  only in `hardening.rs` (two syscalls).
* **Fail closed:** every error path returns an error and leaves inputs intact; a failed operation
  cleans its own temporary files.
* **Least privilege:** the Flatpak has no network, and no access to `~/.ssh`, `~/.gnupg`, `~/.aws`,
  `~/.kube`, the password store or the keyrings; the Windows installer is per-user by default; the
  vault is created `0600`.
* **Minimal trusted base:** the UI contains no cryptography. Standard, audited primitives only
  (RustCrypto AES-GCM, Argon2, HKDF, SHA-2); no home-made crypto.
* **Defence in depth:** CRC (typos) → AEAD tag (tamper) → SHA-256 (end to end) → full rebuild
  verified before any deletion.
* **Secure defaults:** *High* encryption, wipe of originals, no overwrite, no network, inactivity
  wipe off until the user enables it.
* **No secrets in telemetry or logs:** there is none. The host name and OS that the old header
  displayed were removed.

## 5. Security testing (ISO 27002 8.29)

| Layer | What | Where it runs |
|---|---|---|
| Unit + integration | About 40 Rust tests including real SLYS 1.5.1 vectors | every push, 3 OSes |
| Adversarial | bit-flip of **every byte** of fragments and seed (CRC recomputed so the AEAD is what is tested), truncation at every length, random garbage, hostile KDF parameters, symlink/TOCTOU cases, password variants | `crates/slys-core/tests/security.rs`, every push |
| Fuzzing | libFuzzer targets for the seed parser (text and structured) and fragment bytes | `fuzz/` (see below) |
| Static | `clippy -D warnings`, `rustfmt`, `flutter analyze` | every push |
| Dependencies | `cargo-deny` + RustSec advisories | every push and weekly |
| UI robustness | no layout overflow from 360 px to 2560 px on every tab, real core through the real FFI | `app/integration_test`, every push |

Run the fuzzers (needs nightly Rust and `cargo install cargo-fuzz`; add `-s none` if AddressSanitizer
refuses to start, as it does on some hardened kernels). A 60-second run of each target (about 19 million
executions in total) found no crashes before the first release:

```
cd fuzz
cargo +nightly fuzz run seed_structured -- -max_total_time=300
cargo +nightly fuzz run fragment_bytes  -- -max_total_time=300
cargo +nightly fuzz run seed_text       -- -max_total_time=300
```

## 6. Residual risks (stated, not hidden)

1. **A compromised or unlocked computer** (malware, keylogger, someone at the keyboard) defeats any
   such tool. Out of scope.
2. **Weak passwords.** Argon2id slows guessing; it cannot rescue "123456". Use a long passphrase.
3. **Plain and Light modes** protect by obscurity (Kerckhoffs: they are not secret-key protection).
   *High* is the default and the only mode recommended.
4. **Memory.** Keys are zeroised, but the password also exists as text in the UI process (Dart
   strings cannot be wiped) and may reach swap/hibernation. Mitigation: encrypted swap, or use the
   CLI with `--password-stdin`. Only Linux is hardened against dumps/ptrace today; Windows and macOS
   have no equivalent yet.
5. **Secure deletion is best effort** on SSDs, copy-on-write/journaling file systems and cloud
   folders. Use full-disk encryption.
6. **Legacy 1.x seeds are not authenticated** (AES-CBC). They can still be read, but a modified file
   can't be detected; the app warns and recommends re-fragmenting.
7. **Seeds are not secret but are metadata**, for example the number of fragments. They hide names
   and sizes (encrypted), but share them with the same care as a recovery hint.
8. **Binaries are not signed yet** (see [SIGNING.md](SIGNING.md)); until then checksums and build
   attestations are the integrity channel.
9. **No external audit.** Treat SLYS as a careful, tested tool, not as certified software.

## 7. ISO/IEC 27002:2022 control mapping

Status: **Done** = implemented and evidenced in this repository. **Partial** = implemented in part.
**Owner action** = needs a decision or setting outside the code (GitHub org settings, certificates,
policies). **N/A** = does not apply to a local, offline, single-user tool.

| Control | Title | Status | How / evidence |
|---|---|---|---|
| 5.7 | Threat intelligence | Done | Weekly `cargo-deny` run against RustSec; Dependabot for crates, pub and Actions |
| 5.8 | Information security in project management | Done | This document; threat model §3; requirements §1 |
| 5.19 / 5.21 | Supplier relationships / ICT supply chain | Done | `deny.toml` (sources, bans, licences), locked deps, pinned Actions, SBOM per release |
| 5.20 / 5.22 | Supplier agreements / monitoring | Partial | No suppliers beyond open-source dependencies; monitoring = Dependabot + weekly audit |
| 5.23 | Cloud services | N/A at runtime | The program never uses cloud services. CI uses GitHub Actions (pinned, minimal permissions) |
| 5.24–5.28 | Incident management | Partial | Private reporting channel and process in `SECURITY.md`; response times are an owner decision |
| 5.34 | Privacy / PII | Done | No telemetry, no network, no accounts; host name display removed |
| 5.37 | Documented operating procedures | Done | `RELEASING.md`, `DEVELOPMENT.md`, `SIGNING.md` |
| 6.x / 7.x | People / physical | Owner action | Organisational; outside this repository |
| 8.4 | Access to source code | Owner action | Enable branch protection on `main` (required CI, review), 2FA for maintainers, signed commits |
| 8.5 | Secure authentication | N/A | No accounts. Password handling per SR-6 |
| 8.7 | Protection against malware | Partial | Checksums + provenance attestations now; no code signing yet |
| 8.8 | Technical vulnerability management | Done | `cargo-deny` on push and weekly; disclosure policy in `SECURITY.md` |
| 8.9 | Configuration management | Done | Single version source, `Cargo.lock`, `deny.toml`, Flatpak manifest, `check-version.sh` in CI |
| 8.10 | Information deletion | Partial | Verified, best-effort secure delete with documented limits; inactivity wipe (no UI yet) |
| 8.12 | Data leakage prevention | Done | No outbound channel exists; Flatpak has no network |
| 8.13 | Backup | N/A | By design the user keeps seed + password; loss is unrecoverable and documented |
| 8.15 | Logging | Done | Intentionally no logs of secrets or file names; no telemetry |
| 8.19 | Installation of software | Done | Per-user installer, sandboxed Flatpak with narrowed filesystem access |
| 8.20–8.22 | Network security | Done | No network use at all; enforced by `cargo-deny` bans and Flatpak permissions |
| 8.24 | Use of cryptography | Done | AES-256-GCM, Argon2id, HKDF-SHA256, SHA-256; parameters in the seed for agility; versioned formats ([FORMAT.md](FORMAT.md)) |
| 8.25 | Secure development lifecycle | Done | Threat model → tests → CI gates → reviewed releases (this document, `CONTRIBUTING.md`, PR template) |
| 8.26 | Application security requirements | Done | SR-1…SR-8 (§1) |
| 8.27 | Secure system architecture | Done | §2 and §4 |
| 8.28 | Secure coding | Done | Memory-safe language, `deny(unsafe_code)`, clippy as errors, input validation at the boundary, no secret-dependent branching of our own (comparisons are done by the AEAD/hash libraries) |
| 8.29 | Security testing | Done | §5 |
| 8.30 | Outsourced development | N/A | Open-source contributions follow `CONTRIBUTING.md` and review |
| 8.31 | Separation of dev / test / production | Done | Weak-KDF mode only in test builds; `SLYS_CONFIG_DIR` isolates test data; fixtures are synthetic |
| 8.32 | Change management | Partial | PR template with security checklist, CI required checks (**owner action:** mark them "required" in branch protection) |
| 8.33 | Test information | Done | Only synthetic data in tests and fixtures |

## 8. Maintaining this

* Any change that touches parsing, cryptography, file creation/deletion, the Flatpak permissions or
  the workflows must update §3/§7 and add a test that fails without the change.
* A new dependency needs a reason in the pull request; `cargo deny check` must stay green.
* Re-read §6 before every release and before saying anything about SLYS's security in public.
