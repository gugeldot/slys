use flutter_rust_bridge::frb;

#[derive(Clone, Debug)]
pub struct VersionInfo {
    /// SemVer of the app and core (they share one number).
    pub version: String,
    /// Seed format this build writes.
    pub seed_format: u8,
    /// Short git commit, or "unknown".
    pub commit: String,
}

#[frb(sync)]
pub fn version_info() -> VersionInfo {
    let v = slys_core::version();
    VersionInfo { version: v.core.to_string(), seed_format: v.seed_format, commit: v.commit.to_string() }
}
