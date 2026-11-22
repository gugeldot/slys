## What and why

## Checklist
- [ ] `make lint && make test` pass
- [ ] Untrusted input (seeds, fragments, names) is handled as hostile: errors not panics, bounded work
- [ ] No new network access, telemetry or dependency without a reason written above
- [ ] If crypto / formats / file handling / permissions / workflows changed: test added and
      `documentation/SECURITY_ARCHITECTURE.md` updated
- [ ] `cargo deny check` is green
