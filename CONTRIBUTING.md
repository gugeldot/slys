# Contributing

Thanks for looking. A few ground rules, mostly because this is security software:

* **Security issues** go through the private channel in [SECURITY.md](SECURITY.md), not public
  issues.
* **Keep the core small and boring.** Anything that touches formats or cryptography needs a test,
  an update to [documentation/FORMAT.md](documentation/FORMAT.md) and, if the format changes, a new version number
  (never silently change what version 2 means).
* **No network access, no telemetry, no new dependencies without a reason.** Cryptographic
  dependencies must be well-known RustCrypto crates.
* **Never weaken a safety rule**: verify before deleting, atomic writes, errors instead of
  guessing.

## Secure development checklist

Every pull request that touches parsing, cryptography, file creation or deletion, permissions or
the workflows must (details in [documentation/SECURITY_ARCHITECTURE.md](documentation/SECURITY_ARCHITECTURE.md)):

* treat seeds, fragments and file names as **hostile input** (errors, never panics; bounded work);
* create files exclusively and with unguessable temporary names (no check-then-write races, no
  following symlinks);
* come with a test that fails without the change (see `crates/slys-core/tests/security.rs`);
* keep `cargo deny check`, `cargo clippy -D warnings` and the tests green;
* update the threat model / control table if a control is added, changed or removed.

## Workflow

1. Fork, branch, make the change.
2. `make lint && make test` (see [documentation/DEVELOPMENT.md](documentation/DEVELOPMENT.md)).
3. Open a pull request describing *why*. Small PRs get reviewed faster.

By contributing you agree that your work is licensed under GPL-3.0-or-later, like the project.
