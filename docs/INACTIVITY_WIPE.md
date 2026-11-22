# Inactivity wipe: design

Status: **implemented in the core and the CLI (`slys inactivity ...`), opt-in, disabled by
default. Not yet exposed in the app UI** (planned for 2.0). Do not describe it as a finished
feature in user-facing material until the UI ships.

## What it is for

Someone who disappears (or loses access to their computer) may want the *local record of their
seeds* to go away on its own after a period of inactivity, while the fragments stay where they are.
Fragments are already useless without seed + password; the seed list is the convenient pointer
that would make an attacker's life easier.

## What it does

If enabled and the last activity was more than N days ago, the next check (done at app startup,
before anything reads the list) securely deletes:

* `seeds.json` (the saved seeds), and
* `inactivity.json` (its own state).

Activity is recorded when the app starts. After a wipe the state file is gone, so the feature is
back to *disabled* until the user turns it on again.

## What it deliberately does not do

* **It does not touch the fragments.** They are encrypted; deleting them would turn a
  recoverable situation into data loss, for no security gain.
* **It does not delete the program.** Removing the executable protects nothing, and a program
  deleting itself is more dangerous than useful.
* **It is not tamper-proof.** Whoever controls the machine controls its clock and decides when
  SLYS runs. It protects against the casual and the late discoverer, not against a targeted
  forensic attacker, who can copy the file first.
* **It does not promise erasure on every disk.** It uses the same best-effort overwrite as the
  rest of SLYS (see SECURITY.md).

## Why the "recoverable via the seed" promise still holds

The seed is the user's own backup (paper, password manager). Wiping the *list* in the app does not
affect it: reinstalling SLYS and pasting the seed rebuilds the file as long as the fragments exist.

## Triggers considered

| Option | Verdict |
|---|---|
| Check at app start | **Chosen**: simple, honest, no background process. |
| Background service / systemd timer / Task Scheduler | Possible later as an extra, opt-in. Adds an always-on component and a larger attack surface. |
| Network "dead man's switch" | Rejected: SLYS has no network access by design. |

## Planned for the UI (2.0)

A switch and a number of days in Settings, a visible "armed, N days left" state, a clear warning
about the limits above, and a one-click "disable".
