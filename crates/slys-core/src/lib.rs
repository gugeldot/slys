//! # slys-core
//!
//! Fragment a file into encrypted pieces and rebuild it later from a *seed* and a *password*.
//!
//! * [`fragment`] / [`recompose`]: the two main operations.
//! * [`inspect_seed`]: check a seed (typos, version) without the password.
//! * [`vault`]: the local list of saved seeds.
//! * [`inactivity`]: opt-in wipe of the local seed list after a period of inactivity.
//! * [`version`]: build information.
//!
//! Security model, file formats and limitations: see `docs/FORMAT.md` and `SECURITY.md`.

pub mod crypto;
pub mod error;
pub mod format;
mod fragment;
pub mod inactivity;
mod legacy;
mod ops;
pub mod vault;
pub mod version;
pub mod wipe;

pub use crypto::KdfParams;
pub use error::{Error, Result};
pub use format::{Mode, FORMAT_VERSION, MAX_PARTS, MIN_PARTS};
pub use ops::{
    fragment, recompose, DeleteMode, FragmentOptions, FragmentReport, Progress, RecomposeOptions,
    RecomposeReport, Stage,
};
pub use version::{version, VersionInfo};

/// What can be learned from a seed without the password.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SeedInfo {
    /// Seed format 2 (SLYS 1.6+). The text is well formed and its checksum is correct.
    V2 { kdf: KdfParams },
    /// Seed from SLYS 1.x. It has no checksum, so only the password can confirm it.
    Legacy,
}

/// Quick validation of pasted seed text: catches typos before asking for a password.
pub fn inspect_seed(text: &str) -> Result<SeedInfo> {
    if text.trim_start().starts_with(format::TEXT_PREFIX) {
        let h = format::inspect(text)?;
        Ok(SeedInfo::V2 { kdf: h.kdf })
    } else {
        let clean: String = text.chars().filter(|c| !c.is_whitespace()).collect();
        use base64::Engine as _;
        match base64::engine::general_purpose::STANDARD.decode(clean) {
            Ok(b) if b.len() >= 48 => Ok(SeedInfo::Legacy),
            _ => Err(Error::SeedMalformed("not a SLYS seed")),
        }
    }
}
