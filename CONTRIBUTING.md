# Contributing

Thanks for looking. A few ground rules, mostly because this is security software:

* **Security issues** go through the private channel in [SECURITY.md](SECURITY.md), not public
  issues.
* **Keep the core small and boring.** Anything that touches formats or cryptography needs a test,
  an update to [docs/FORMAT.md](docs/FORMAT.md) and, if the format changes, a new version number
  (never silently change what version 2 means).
* **No network access, no telemetry, no new dependencies without a reason.** Cryptographic
  dependencies must be well-known RustCrypto crates.
* **Never weaken a safety rule**: verify before deleting, atomic writes, errors instead of
  guessing.

## Workflow

1. Fork, branch, make the change.
2. `make lint && make test` (see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)).
3. Open a pull request describing *why*. Small PRs get reviewed faster.

By contributing you agree that your work is licensed under GPL-3.0-or-later, like the project.
