//! Version information shown in the About screen and by `slys version`.

use crate::format::FORMAT_VERSION;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct VersionInfo {
    /// Semantic version of the SLYS core (the same number as the app; see scripts/set-version.sh).
    pub core: &'static str,
    /// Seed format written by this build.
    pub seed_format: u8,
    /// Short git commit this binary was built from, or "unknown".
    pub commit: &'static str,
}

pub fn version() -> VersionInfo {
    VersionInfo {
        core: env!("CARGO_PKG_VERSION"),
        seed_format: FORMAT_VERSION,
        commit: env!("SLYS_GIT_COMMIT"),
    }
}
