//! The two operations users care about: `fragment` and `recompose`.
//!
//! Safety rules enforced here:
//! * Nothing is deleted until the result has been verified byte-for-byte (SHA-256).
//! * Output files are written to a temporary name and renamed only when complete.
//! * A failed decryption is an error. It never produces a corrupted output file.
//! * Names read from a seed are never allowed to contain directories.

use std::fs::{self, File, OpenOptions};
use std::io::{self, BufReader, BufWriter, Read, Write};
use std::path::{Path, PathBuf};

use rand::Rng;

use crate::crypto::{KdfParams, MasterKey};
use crate::error::{Error, Result};
use crate::format::{self, FragmentEntry, Mode, Payload, MAX_PARTS, MIN_PARTS};
use crate::fragment::{aad, decrypt_stream, encrypt_stream, HashReader, HashWriter};
use crate::legacy;
use crate::wipe;

pub const FRAGMENT_EXTENSION: &str = "slys";

/// What to do with files that are no longer needed (the original after fragmenting, the
/// fragments after rebuilding).
#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
pub enum DeleteMode {
    /// Leave them in place.
    Keep,
    /// Normal deletion (the data can still be recovered with forensic tools).
    Delete,
    /// Best-effort secure wipe: overwrite, flush, unlink. See `wipe` for its limits.
    #[default]
    Wipe,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Stage {
    /// Running the (deliberately slow) password hashing.
    Deriving,
    Encrypting,
    /// Re-reading what was written and checking it matches the original.
    Verifying,
    Rebuilding,
    Cleaning,
}

#[derive(Clone, Copy, Debug)]
pub struct Progress {
    pub stage: Stage,
    pub done: u64,
    pub total: u64,
}

#[derive(Clone, Debug)]
pub struct FragmentOptions {
    pub mode: Mode,
    pub parts: usize,
    pub kdf: KdfParams,
    pub delete_original: DeleteMode,
}

impl Default for FragmentOptions {
    fn default() -> Self {
        FragmentOptions {
            mode: Mode::Full,
            parts: 5,
            kdf: KdfParams::default(),
            delete_original: DeleteMode::Wipe,
        }
    }
}

#[derive(Debug)]
pub struct FragmentReport {
    /// The seed. Keep it: without it (and the password) the file cannot be rebuilt.
    pub seed: String,
    pub fragments: Vec<PathBuf>,
    pub original_deleted: bool,
    pub warnings: Vec<String>,
}

#[derive(Clone, Debug, Default)]
pub struct RecomposeOptions {
    /// Replace the output file if it exists.
    pub overwrite: bool,
    pub delete_fragments: DeleteMode,
}

#[derive(Debug)]
pub struct RecomposeReport {
    pub output: PathBuf,
    pub fragments_deleted: bool,
    pub warnings: Vec<String>,
}

fn random_fragment_name() -> String {
    const ALPHABET: &[u8] = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let mut rng = rand::rngs::OsRng;
    let stem: String = (0..16)
        .map(|_| ALPHABET[rng.gen_range(0..ALPHABET.len())] as char)
        .collect();
    format!("{stem}.{FRAGMENT_EXTENSION}")
}

/// File names that are legal in a seed may not be legal on every OS.
pub(crate) fn output_file_name(name: &str) -> String {
    if cfg!(windows) {
        name.chars()
            .map(|c| {
                if matches!(c, '<' | '>' | ':' | '"' | '|' | '?' | '*') {
                    '_'
                } else {
                    c
                }
            })
            .collect()
    } else {
        name.to_string()
    }
}

fn copy_counted<R: Read, W: Write>(
    r: &mut R,
    w: &mut W,
    on_bytes: &mut dyn FnMut(u64),
) -> io::Result<()> {
    let mut buf = vec![0u8; 64 * 1024];
    loop {
        let n = match r.read(&mut buf) {
            Ok(0) => return Ok(()),
            Ok(n) => n,
            Err(e) if e.kind() == io::ErrorKind::Interrupted => continue,
            Err(e) => return Err(e),
        };
        w.write_all(&buf[..n])?;
        on_bytes(n as u64);
    }
}

/// Reads every fragment in order, checks it, decrypts it if needed and writes the plaintext.
fn assemble<W: Write>(
    payload: &Payload,
    master: &MasterKey,
    dir: &Path,
    out: &mut W,
    on_bytes: &mut dyn FnMut(u64),
) -> Result<()> {
    let total = payload.fragments.len();
    for (i, entry) in payload.fragments.iter().enumerate() {
        let corrupted = || Error::FragmentCorrupted(entry.name.clone());
        let file = File::open(dir.join(&entry.name)).map_err(|e| {
            if e.kind() == io::ErrorKind::NotFound {
                Error::FragmentMissing(entry.name.clone())
            } else {
                Error::Io(e)
            }
        })?;
        if file.metadata()?.len() != entry.size {
            return Err(corrupted());
        }
        let mut reader = HashReader::new(BufReader::new(file));
        if payload.mode.encrypts(i, total) {
            let key = master.fragment_key(&payload.seed_id, i as u32);
            decrypt_stream(
                &mut reader,
                out,
                &key,
                &aad(&payload.seed_id, i as u32),
                on_bytes,
            )
            .map_err(|e| {
                if matches!(e, Error::Crypto) {
                    corrupted()
                } else {
                    e
                }
            })?;
        } else {
            copy_counted(&mut reader, out, on_bytes)?;
        }
        let (digest, read) = reader.finish();
        if digest != entry.sha256 || read != entry.size {
            return Err(corrupted());
        }
    }
    Ok(())
}

pub(crate) fn delete_fragment_files<'a>(
    dir: &Path,
    names: impl Iterator<Item = &'a str>,
    mode: DeleteMode,
    progress: &mut dyn FnMut(Progress),
) -> (bool, Vec<String>) {
    if mode == DeleteMode::Keep {
        return (false, vec![]);
    }
    let names: Vec<&str> = names.collect();
    let mut warnings = vec![];
    for (i, name) in names.iter().enumerate() {
        let path = dir.join(name);
        let r = match mode {
            DeleteMode::Wipe => wipe::secure_delete(&path).map(|_| ()),
            _ => fs::remove_file(&path).map_err(Error::from),
        };
        if let Err(e) = r {
            warnings.push(format!("Could not delete {name}: {e}"));
        }
        progress(Progress {
            stage: Stage::Cleaning,
            done: (i + 1) as u64,
            total: names.len() as u64,
        });
    }
    (warnings.len() < names.len(), warnings)
}

/// Splits `input` into `opts.parts` fragments inside `output_dir` and returns the seed.
pub fn fragment(
    input: &Path,
    output_dir: &Path,
    password: &str,
    opts: &FragmentOptions,
    progress: &mut dyn FnMut(Progress),
) -> Result<FragmentReport> {
    if password.is_empty() {
        return Err(Error::EmptyPassword);
    }
    if !(MIN_PARTS..=MAX_PARTS).contains(&opts.parts) {
        return Err(Error::InvalidParts {
            min: MIN_PARTS,
            max: MAX_PARTS,
        });
    }
    let meta =
        fs::metadata(input).map_err(|_| Error::InputNotFound(input.display().to_string()))?;
    if !meta.is_file() {
        return Err(Error::InputNotFound(input.display().to_string()));
    }
    let size = meta.len();
    if size < opts.parts as u64 {
        return Err(Error::TooManyParts {
            size,
            parts: opts.parts,
        });
    }
    let original_name = input
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .ok_or_else(|| Error::InputNotFound(input.display().to_string()))?;
    if !format::safe_name(&original_name) {
        return Err(Error::UnsafeName);
    }
    fs::create_dir_all(output_dir)?;

    let total_work = size.saturating_mul(2);
    let mut done = 0u64;
    progress(Progress {
        stage: Stage::Deriving,
        done: 0,
        total: total_work,
    });

    let salt = format::new_salt();
    let master = MasterKey::derive(password, &salt, opts.kdf)?;
    let seed_id: [u8; 16] = crate::crypto::random_bytes();

    let mut created: Vec<PathBuf> = Vec::new();
    let built = (|| -> Result<(Payload, String)> {
        let mut reader = HashReader::new(BufReader::new(File::open(input)?));
        let base = size / opts.parts as u64;
        let remainder = size % opts.parts as u64;
        let mut entries = Vec::with_capacity(opts.parts);

        for i in 0..opts.parts {
            let len = base + if i == opts.parts - 1 { remainder } else { 0 };
            let (name, path) = loop {
                let name = random_fragment_name();
                let path = output_dir.join(&name);
                if !path.exists() {
                    break (name, path);
                }
            };
            let tmp = path.with_extension("slys.part");
            created.push(tmp.clone());
            let file = OpenOptions::new().write(true).create_new(true).open(&tmp)?;
            let mut writer = HashWriter::new(BufWriter::new(file));
            let mut limited = (&mut reader).take(len);
            let mut tick = |n: u64| {
                done += n;
                progress(Progress {
                    stage: Stage::Encrypting,
                    done,
                    total: total_work,
                });
            };
            if opts.mode.encrypts(i, opts.parts) {
                let key = master.fragment_key(&seed_id, i as u32);
                encrypt_stream(
                    &mut limited,
                    &mut writer,
                    &key,
                    &aad(&seed_id, i as u32),
                    len,
                    &mut tick,
                )?;
            } else {
                copy_counted(&mut limited, &mut writer, &mut tick)?;
            }
            let (buffered, sha256, written) = writer.finish();
            buffered
                .into_inner()
                .map_err(|e| e.into_error())?
                .sync_all()?;
            fs::rename(&tmp, &path)?;
            created.pop();
            created.push(path);
            entries.push(FragmentEntry {
                name,
                size: written,
                sha256,
            });
        }

        let (original_sha256, read) = reader.finish();
        if read != size {
            // The file changed while we were reading it.
            return Err(Error::IntegrityMismatch);
        }
        let payload = Payload {
            seed_id,
            mode: opts.mode,
            original_name,
            original_size: size,
            original_sha256,
            fragments: entries,
        };
        let seed = format::seal(&payload, &master, opts.kdf, &salt)?;

        // Verify what is on disk before touching the original.
        let mut sink = HashWriter::new(io::sink());
        let mut vtick = |n: u64| {
            done += n;
            progress(Progress {
                stage: Stage::Verifying,
                done,
                total: total_work,
            });
        };
        assemble(&payload, &master, output_dir, &mut sink, &mut vtick)?;
        let (_, digest, n) = sink.finish();
        if digest != payload.original_sha256 || n != size {
            return Err(Error::IntegrityMismatch);
        }
        Ok((payload, seed))
    })();

    let (payload, seed) = match built {
        Ok(v) => v,
        Err(e) => {
            for p in &created {
                let _ = fs::remove_file(p);
            }
            return Err(e);
        }
    };

    let mut warnings = vec![];
    let mut original_deleted = false;
    if opts.delete_original != DeleteMode::Keep {
        progress(Progress {
            stage: Stage::Cleaning,
            done: 0,
            total: 1,
        });
        let r = match opts.delete_original {
            DeleteMode::Wipe => wipe::secure_delete(input).map(|_| ()),
            _ => fs::remove_file(input).map_err(Error::from),
        };
        match r {
            Ok(()) => original_deleted = true,
            Err(e) => warnings.push(format!("Could not delete the original file: {e}")),
        }
    }
    let fragments = payload
        .fragments
        .iter()
        .map(|f| output_dir.join(&f.name))
        .collect();
    Ok(FragmentReport {
        seed,
        fragments,
        original_deleted,
        warnings,
    })
}

/// Rebuilds a file from a seed (v2, or v1 from SLYS 1.x), the password and the fragments.
pub fn recompose(
    seed: &str,
    password: &str,
    fragments_dir: &Path,
    output_dir: &Path,
    opts: &RecomposeOptions,
    progress: &mut dyn FnMut(Progress),
) -> Result<RecomposeReport> {
    if password.is_empty() {
        return Err(Error::EmptyPassword);
    }
    if !seed.trim_start().starts_with(format::TEXT_PREFIX) {
        return legacy::recompose(seed, password, fragments_dir, output_dir, opts, progress);
    }

    progress(Progress {
        stage: Stage::Deriving,
        done: 0,
        total: 0,
    });
    let opened = format::open(seed, password)?;
    let payload = opened.payload;
    let out_path = output_dir.join(output_file_name(&payload.original_name));
    if out_path.exists() && !opts.overwrite {
        return Err(Error::OutputExists(out_path.display().to_string()));
    }
    fs::create_dir_all(output_dir)?;
    let tmp = out_path.with_extension("slys-part");

    let total = payload.original_size;
    let mut done = 0u64;
    let result = (|| -> Result<()> {
        let mut writer = HashWriter::new(BufWriter::new(File::create(&tmp)?));
        let mut tick = |n: u64| {
            done += n;
            progress(Progress {
                stage: Stage::Rebuilding,
                done,
                total,
            });
        };
        assemble(
            &payload,
            &opened.master,
            fragments_dir,
            &mut writer,
            &mut tick,
        )?;
        let (buffered, digest, n) = writer.finish();
        if digest != payload.original_sha256 || n != payload.original_size {
            return Err(Error::IntegrityMismatch);
        }
        buffered
            .into_inner()
            .map_err(|e| e.into_error())?
            .sync_all()?;
        Ok(())
    })();
    if let Err(e) = result {
        let _ = fs::remove_file(&tmp);
        return Err(e);
    }
    fs::rename(&tmp, &out_path)?;

    let (fragments_deleted, warnings) = delete_fragment_files(
        fragments_dir,
        payload.fragments.iter().map(|f| f.name.as_str()),
        opts.delete_fragments,
        progress,
    );
    Ok(RecomposeReport {
        output: out_path,
        fragments_deleted,
        warnings,
    })
}
