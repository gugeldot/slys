//! Process hardening. Best effort, never fatal: if the OS refuses, SLYS still works.
//!
//! The master key and the password only live in memory while an operation runs, but a crash
//! dump or another program of the same user attaching a debugger could read them. So:
//! * Linux: the process is marked non-dumpable (no core dumps, no `ptrace` by same-user
//!   processes, `/proc/<pid>/mem` closed) and the core-dump size limit is set to 0.
//! * Other platforms: nothing here yet (see docs/SECURITY_ARCHITECTURE.md, residual risks).
//!
//! This is the only module in the crate allowed to use `unsafe`.

#![allow(unsafe_code)]

/// Call once, as early as possible in the program. Returns what could be applied.
pub fn harden_process() -> Vec<&'static str> {
    #[allow(unused_mut)]
    let mut applied = Vec::new();
    #[cfg(target_os = "linux")]
    {
        // SAFETY: plain syscalls with constant, valid arguments.
        unsafe {
            if libc::prctl(libc::PR_SET_DUMPABLE, 0, 0, 0, 0) == 0 {
                applied.push("non-dumpable");
            }
            let zero = libc::rlimit {
                rlim_cur: 0,
                rlim_max: 0,
            };
            if libc::setrlimit(libc::RLIMIT_CORE, &zero) == 0 {
                applied.push("no-core-dumps");
            }
        }
    }
    applied
}

#[cfg(all(test, target_os = "linux"))]
mod tests {
    #[test]
    fn marks_process_non_dumpable() {
        let applied = super::harden_process();
        assert!(applied.contains(&"non-dumpable"));
        // SAFETY: reads a flag.
        let v = unsafe { libc::prctl(libc::PR_GET_DUMPABLE, 0, 0, 0, 0) };
        assert_eq!(v, 0);
    }
}
