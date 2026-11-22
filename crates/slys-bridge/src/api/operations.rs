use std::path::Path;

use flutter_rust_bridge::frb;
use slys_core as core;

use crate::frb_generated::StreamSink;

/// How much of the file is encrypted.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EncryptionMode {
    /// Every fragment encrypted and authenticated. Recommended.
    Full,
    /// Only the first and last fragment. The rest stays readable.
    Light,
    /// Nothing encrypted (the seed still is). Obfuscation only.
    Plain,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DeletePolicy {
    Keep,
    Delete,
    Wipe,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Stage {
    Deriving,
    Encrypting,
    Verifying,
    Rebuilding,
    Cleaning,
}

#[derive(Clone, Debug)]
pub struct FragmentRequest {
    pub input_path: String,
    pub output_dir: String,
    pub password: String,
    pub mode: EncryptionMode,
    pub parts: u32,
    pub delete_original: DeletePolicy,
}

#[derive(Clone, Debug)]
pub struct RecomposeRequest {
    pub seed: String,
    pub password: String,
    pub fragments_dir: String,
    pub output_dir: String,
    pub overwrite: bool,
    pub delete_fragments: DeletePolicy,
}

/// Errors carry a stable `code` (for the UI to react to) and a human message.
#[derive(Clone, Debug)]
pub struct SlysError {
    pub code: String,
    pub message: String,
}

#[derive(Clone, Debug)]
pub struct FragmentOutcome {
    pub seed: String,
    pub fragment_count: u32,
    pub original_deleted: bool,
    pub warnings: Vec<String>,
}

#[derive(Clone, Debug)]
pub struct RecomposeOutcome {
    pub output_path: String,
    pub fragments_deleted: bool,
    pub warnings: Vec<String>,
}

/// Events streamed to the UI while an operation runs. The stream ends after `Failed` or one of
/// the `Fragmented` / `Recomposed` events.
#[derive(Clone, Debug)]
pub enum OperationEvent {
    Progress { stage: Stage, done: u64, total: u64 },
    Fragmented(FragmentOutcome),
    Recomposed(RecomposeOutcome),
    Failed(SlysError),
}

pub(crate) fn to_error(e: &core::Error) -> SlysError {
    use core::Error::*;
    let code = match e {
        Io(_) => "io",
        InputNotFound(_) => "input_not_found",
        TooManyParts { .. } => "too_many_parts",
        InvalidParts { .. } => "invalid_parts",
        EmptyPassword => "empty_password",
        SeedChecksum => "seed_checksum",
        SeedMalformed(_) => "seed_malformed",
        UnsupportedVersion(_) => "unsupported_version",
        WrongPasswordOrTampered => "wrong_password",
        LegacyDecrypt => "wrong_password_legacy",
        FragmentMissing(_) => "fragment_missing",
        FragmentCorrupted(_) => "fragment_corrupted",
        IntegrityMismatch => "integrity",
        OutputExists(_) => "output_exists",
        UnsafeName => "unsafe_name",
        KdfParams => "kdf_params",
        Crypto => "crypto",
        Storage(_) => "storage",
    };
    SlysError {
        code: code.into(),
        message: e.to_string(),
    }
}

fn mode(m: EncryptionMode) -> core::Mode {
    match m {
        EncryptionMode::Full => core::Mode::Full,
        EncryptionMode::Light => core::Mode::Light,
        EncryptionMode::Plain => core::Mode::Plain,
    }
}

fn delete(d: DeletePolicy) -> core::DeleteMode {
    match d {
        DeletePolicy::Keep => core::DeleteMode::Keep,
        DeletePolicy::Delete => core::DeleteMode::Delete,
        DeletePolicy::Wipe => core::DeleteMode::Wipe,
    }
}

fn stage(s: core::Stage) -> Stage {
    match s {
        core::Stage::Deriving => Stage::Deriving,
        core::Stage::Encrypting => Stage::Encrypting,
        core::Stage::Verifying => Stage::Verifying,
        core::Stage::Rebuilding => Stage::Rebuilding,
        core::Stage::Cleaning => Stage::Cleaning,
    }
}

/// Splits a file. Returns a stream of events; the last one is `Fragmented` or `Failed`.
/// Runs on a worker thread, so the UI never freezes during the (deliberately slow) key derivation.
pub fn fragment(req: FragmentRequest, events: StreamSink<OperationEvent>) {
    let opts = core::FragmentOptions {
        mode: mode(req.mode),
        parts: req.parts as usize,
        kdf: core::KdfParams::default(),
        delete_original: delete(req.delete_original),
    };
    let mut last_pct = u64::MAX;
    let mut progress = |p: core::Progress| {
        // Throttle to 1% steps so a huge file does not flood the UI thread.
        let pct = (p.done * 100).checked_div(p.total).unwrap_or(0);
        if pct != last_pct || p.total == 0 {
            last_pct = pct;
            let _ = events.add(OperationEvent::Progress {
                stage: stage(p.stage),
                done: p.done,
                total: p.total,
            });
        }
    };
    let result = core::fragment(
        Path::new(&req.input_path),
        Path::new(&req.output_dir),
        &req.password,
        &opts,
        &mut progress,
    );
    let _ = events.add(match result {
        Ok(r) => OperationEvent::Fragmented(FragmentOutcome {
            seed: r.seed,
            fragment_count: r.fragments.len() as u32,
            original_deleted: r.original_deleted,
            warnings: r.warnings,
        }),
        Err(e) => OperationEvent::Failed(to_error(&e)),
    });
}

/// Rebuilds a file. Same event protocol as [`fragment`].
pub fn recompose(req: RecomposeRequest, events: StreamSink<OperationEvent>) {
    let opts = core::RecomposeOptions {
        overwrite: req.overwrite,
        delete_fragments: delete(req.delete_fragments),
    };
    let mut last_pct = u64::MAX;
    let mut progress = |p: core::Progress| {
        let pct = (p.done * 100).checked_div(p.total).unwrap_or(0);
        if pct != last_pct || p.total == 0 {
            last_pct = pct;
            let _ = events.add(OperationEvent::Progress {
                stage: stage(p.stage),
                done: p.done,
                total: p.total,
            });
        }
    };
    let result = core::recompose(
        &req.seed,
        &req.password,
        Path::new(&req.fragments_dir),
        Path::new(&req.output_dir),
        &opts,
        &mut progress,
    );
    let _ = events.add(match result {
        Ok(r) => OperationEvent::Recomposed(RecomposeOutcome {
            output_path: r.output.display().to_string(),
            fragments_deleted: r.fragments_deleted,
            warnings: r.warnings,
        }),
        Err(e) => OperationEvent::Failed(to_error(&e)),
    });
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SeedKind {
    /// Format 2 with a valid checksum.
    V2,
    /// From SLYS 1.x (read-only support).
    Legacy,
}

/// Validates pasted seed text (typos, version) without a password.
#[frb(sync)]
pub fn inspect_seed(text: String) -> Result<SeedKind, SlysError> {
    match core::inspect_seed(&text) {
        Ok(core::SeedInfo::V2 { .. }) => Ok(SeedKind::V2),
        Ok(core::SeedInfo::Legacy) => Ok(SeedKind::Legacy),
        Err(e) => Err(to_error(&e)),
    }
}
