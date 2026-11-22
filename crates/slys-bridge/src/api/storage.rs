use flutter_rust_bridge::frb;
use slys_core::inactivity::{Inactivity, Status};
use slys_core::vault::Vault;

use super::operations::{to_error, SlysError};

#[derive(Clone, Debug)]
pub struct SavedSeed {
    pub id: String,
    pub name: String,
    pub seed: String,
    /// Unix seconds; 0 for seeds saved by SLYS 1.x.
    pub created_at: u64,
}

fn vault() -> Result<Vault, SlysError> {
    Vault::open_default().map_err(|e| to_error(&e))
}

#[frb(sync)]
pub fn seeds_list() -> Result<Vec<SavedSeed>, SlysError> {
    let entries = vault()?.list().map_err(|e| to_error(&e))?;
    Ok(entries
        .into_iter()
        .map(|e| SavedSeed {
            id: e.id,
            name: e.name,
            seed: e.seed,
            created_at: e.created_at,
        })
        .collect())
}

#[frb(sync)]
pub fn seeds_add(seed: String, name: Option<String>) -> Result<SavedSeed, SlysError> {
    let e = vault()?
        .add(&seed, name.as_deref())
        .map_err(|e| to_error(&e))?;
    Ok(SavedSeed {
        id: e.id,
        name: e.name,
        seed: e.seed,
        created_at: e.created_at,
    })
}

#[frb(sync)]
pub fn seeds_remove(id: String) -> Result<bool, SlysError> {
    vault()?.remove(&id).map_err(|e| to_error(&e))
}

#[frb(sync)]
pub fn seeds_rename(id: String, name: String) -> Result<(), SlysError> {
    vault()?.rename(&id, &name).map_err(|e| to_error(&e))
}

/// State of the opt-in inactivity wipe.
#[derive(Clone, Debug)]
pub enum InactivityStatus {
    Disabled,
    Armed { days_left: u32 },
    Expired,
}

#[frb(sync)]
pub fn inactivity_status() -> Result<InactivityStatus, SlysError> {
    let i = Inactivity::open_default().map_err(|e| to_error(&e))?;
    Ok(match i.status().map_err(|e| to_error(&e))? {
        Status::Disabled => InactivityStatus::Disabled,
        Status::Armed { seconds_left } => InactivityStatus::Armed {
            days_left: (seconds_left / 86_400) as u32,
        },
        Status::Expired => InactivityStatus::Expired,
    })
}

/// What the Settings screen shows: whether it is on, after how many days, and how long is left.
#[derive(Clone, Debug)]
pub struct InactivitySettings {
    pub enabled: bool,
    pub days: u32,
    /// Whole days until the wipe; `None` when disabled. 0 means "less than a day".
    pub days_left: Option<u32>,
}

#[frb(sync)]
pub fn inactivity_settings() -> Result<InactivitySettings, SlysError> {
    let i = Inactivity::open_default().map_err(|e| to_error(&e))?;
    let state = i.state().map_err(|e| to_error(&e))?;
    let days_left = match i.status().map_err(|e| to_error(&e))? {
        Status::Disabled => None,
        Status::Armed { seconds_left } => Some((seconds_left / 86_400) as u32),
        Status::Expired => Some(0),
    };
    Ok(InactivitySettings {
        enabled: state.enabled,
        days: state.days,
        days_left,
    })
}

#[frb(sync)]
pub fn inactivity_configure(enabled: bool, days: u32) -> Result<(), SlysError> {
    Inactivity::open_default()
        .and_then(|i| i.configure(enabled, days).map(|_| ()))
        .map_err(|e| to_error(&e))
}

/// Call once at startup, before anything else. Returns true if the local seed list was wiped.
#[frb(sync)]
pub fn inactivity_enforce_and_touch() -> Result<bool, SlysError> {
    let i = Inactivity::open_default().map_err(|e| to_error(&e))?;
    let wiped = i.enforce().map_err(|e| to_error(&e))?;
    // enforce() removed the state file when it wiped; touch() recreates a fresh (disabled) one.
    i.touch().map_err(|e| to_error(&e))?;
    Ok(wiped)
}
