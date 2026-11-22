//! Opt-in "inactivity wipe" of the local data.
//!
//! What it does: if enabled and the app was not used for N days, the next check securely
//! deletes the local seed list (`seeds.json`) and the inactivity state.
//!
//! What it deliberately does NOT do, and why (see documentation/INACTIVITY_WIPE.md):
//! * It does not touch the fragments. They are encrypted and useless without seed + password,
//!   which is exactly the protection they already have.
//! * It does not delete the program. Removing the executable protects nothing.
//! * It is not tamper-proof: the clock and the moment the program runs are controlled by
//!   whoever has the machine. It is a convenience safeguard, not a guarantee.
//!
//! Disabled by default.

use std::fs;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};

use crate::error::{Error, Result};
use crate::vault::{default_dir, now, write_atomic, Vault};
use crate::wipe;

const DAY: u64 = 24 * 60 * 60;

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct State {
    pub enabled: bool,
    /// Days of inactivity before the wipe.
    pub days: u32,
    /// Unix seconds of the last activity.
    pub last_active: u64,
}

impl Default for State {
    fn default() -> Self {
        State {
            enabled: false,
            days: 90,
            last_active: now(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Status {
    Disabled,
    /// Active; seconds left before the wipe.
    Armed {
        seconds_left: u64,
    },
    /// The deadline has passed.
    Expired,
}

pub struct Inactivity {
    dir: PathBuf,
}

impl Inactivity {
    pub fn open_default() -> Result<Self> {
        Self::open(default_dir()?)
    }

    pub fn open(dir: impl Into<PathBuf>) -> Result<Self> {
        let dir = dir.into();
        fs::create_dir_all(&dir)?;
        Ok(Inactivity { dir })
    }

    fn path(&self) -> PathBuf {
        self.dir.join("inactivity.json")
    }

    pub fn state(&self) -> Result<State> {
        match fs::read_to_string(self.path()) {
            Ok(t) => serde_json::from_str(&t)
                .map_err(|e| Error::Storage(format!("inactivity.json is not valid: {e}"))),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(State::default()),
            Err(e) => Err(e.into()),
        }
    }

    fn save(&self, s: &State) -> Result<()> {
        write_atomic(
            &self.path(),
            &serde_json::to_vec_pretty(s).map_err(|e| Error::Storage(e.to_string()))?,
        )
    }

    pub fn configure(&self, enabled: bool, days: u32) -> Result<State> {
        if enabled && !(1..=3650).contains(&days) {
            return Err(Error::Storage("days must be between 1 and 3650".into()));
        }
        let s = State {
            enabled,
            days: days.max(1),
            last_active: now(),
        };
        self.save(&s)?;
        Ok(s)
    }

    /// Call whenever the user does something (open the app, fragment, recompose).
    pub fn touch(&self) -> Result<()> {
        let mut s = self.state()?;
        s.last_active = now();
        self.save(&s)
    }

    pub fn status(&self) -> Result<Status> {
        let s = self.state()?;
        if !s.enabled {
            return Ok(Status::Disabled);
        }
        let deadline = s.last_active.saturating_add(s.days as u64 * DAY);
        let t = now();
        Ok(if t >= deadline {
            Status::Expired
        } else {
            Status::Armed {
                seconds_left: deadline - t,
            }
        })
    }

    /// If the deadline has passed, securely deletes the seed list and this state file.
    /// Returns true when a wipe happened. Call it at startup, *before* `touch`.
    pub fn enforce(&self) -> Result<bool> {
        if self.status()? != Status::Expired {
            return Ok(false);
        }
        let vault = Vault::open(&self.dir)?;
        if vault.path().exists() {
            wipe::secure_delete(&vault.path())?;
        }
        wipe::secure_delete(&self.path())?;
        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn disabled_by_default_and_never_wipes() {
        let dir = tempfile::tempdir().unwrap();
        let v = Vault::open(dir.path()).unwrap();
        v.add("seed", None).unwrap();
        let i = Inactivity::open(dir.path()).unwrap();
        assert_eq!(i.status().unwrap(), Status::Disabled);
        assert!(!i.enforce().unwrap());
        assert!(v.path().exists());
    }

    #[test]
    fn expired_wipes_the_vault() {
        let dir = tempfile::tempdir().unwrap();
        let v = Vault::open(dir.path()).unwrap();
        v.add("seed", None).unwrap();
        let i = Inactivity::open(dir.path()).unwrap();
        i.configure(true, 30).unwrap();
        assert!(matches!(i.status().unwrap(), Status::Armed { .. }));
        assert!(!i.enforce().unwrap());
        // pretend the last activity was 31 days ago
        let mut s = i.state().unwrap();
        s.last_active = now() - 31 * DAY;
        i.save(&s).unwrap();
        assert_eq!(i.status().unwrap(), Status::Expired);
        assert!(i.enforce().unwrap());
        assert!(!v.path().exists());
        assert_eq!(fs::read_dir(dir.path()).unwrap().count(), 0);
    }
}
