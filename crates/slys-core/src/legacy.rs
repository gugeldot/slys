//! Read-only support for SLYS 1.x (1.0 - 1.5.x): seeds and fragments made with
//! AES-256-CBC + PBKDF2-HMAC-SHA256 (100,000 iterations), without authentication.
//!
//! This exists so people with seeds from older versions can still recover their files.
//! New data is never written in this format. Unlike 1.x, a failed decryption is now an error
//! (1.x silently wrote the encrypted bytes into the output and then deleted the fragments).

use std::fs;
use std::io::{BufWriter, Write};
use std::path::Path;

use aes::Aes256;
use base64::{engine::general_purpose::STANDARD, Engine as _};
use cbc::Decryptor;
use cipher::block_padding::Pkcs7;
use cipher::{BlockModeDecrypt, KeyIvInit};
use sha2::Sha256;
use zeroize::Zeroizing;

use crate::error::{Error, Result};
use crate::format::{safe_name, Mode};
use crate::ops::{delete_fragment_files, Progress, RecomposeOptions, RecomposeReport, Stage};

const SEPARATOR: &str = "=/#/=";
const END: &str = "|=-=|";
const HEADER_SEPARATOR: &str = "|--|";
/// The 1.x fragment password was `password + SPICE`.
const SPICE: &str = "+2/";
const ITERATIONS: u32 = 100_000;
const SALT_LEN: usize = 16;
const IV_LEN: usize = 16;

pub(crate) struct LegacySeed {
    pub name: String,
    pub mode: Mode,
    pub files: Vec<String>,
}

fn decrypt(data: &[u8], password: &str) -> Result<Vec<u8>> {
    if data.len() < SALT_LEN + IV_LEN {
        return Err(Error::LegacyDecrypt);
    }
    let (salt, rest) = data.split_at(SALT_LEN);
    let (iv, ct) = rest.split_at(IV_LEN);
    let mut key = Zeroizing::new([0u8; 32]);
    pbkdf2::pbkdf2_hmac::<Sha256>(password.as_bytes(), salt, ITERATIONS, &mut *key);
    let mut buf = ct.to_vec();
    let plain = Decryptor::<Aes256>::new_from_slices(&*key, iv)
        .map_err(|_| Error::LegacyDecrypt)?
        .decrypt_padded::<Pkcs7>(&mut buf)
        .map_err(|_| Error::LegacyDecrypt)?;
    Ok(plain.to_vec())
}

pub(crate) fn open_seed(text: &str, password: &str) -> Result<LegacySeed> {
    let clean: String = text.chars().filter(|c| !c.is_whitespace()).collect();
    let raw = STANDARD
        .decode(clean)
        .map_err(|_| Error::SeedMalformed("not a SLYS seed"))?;
    let plain = decrypt(&raw, password)?;
    let plain = String::from_utf8(plain).map_err(|_| Error::LegacyDecrypt)?;

    let body = plain
        .strip_suffix(END)
        .and_then(|s| s.strip_suffix(SEPARATOR))
        .ok_or(Error::SeedMalformed("malformed legacy seed"))?;
    let mut parts = body.split(SEPARATOR);
    let header = parts.next().ok_or(Error::SeedMalformed("no header"))?;
    let mut h = header.splitn(3, HEADER_SEPARATOR);
    let count: usize = h
        .next()
        .and_then(|s| s.parse().ok())
        .ok_or(Error::SeedMalformed("bad header"))?;
    let name = h
        .next()
        .ok_or(Error::SeedMalformed("bad header"))?
        .to_string();
    let mode = match h.next() {
        Some("N") => Mode::Plain,
        Some("P") => Mode::Light,
        Some("T") => Mode::Full,
        _ => return Err(Error::SeedMalformed("bad mode")),
    };
    let files: Vec<String> = parts.map(|s| s.to_string()).collect();
    if files.len() != count {
        return Err(Error::SeedMalformed("fragment count mismatch"));
    }
    if !safe_name(&name) || files.iter().any(|f| !safe_name(f)) {
        return Err(Error::UnsafeName);
    }
    Ok(LegacySeed { name, mode, files })
}

pub(crate) fn recompose(
    seed_text: &str,
    password: &str,
    fragments_dir: &Path,
    output_dir: &Path,
    opts: &RecomposeOptions,
    progress: &mut dyn FnMut(Progress),
) -> Result<RecomposeReport> {
    let seed = open_seed(seed_text, password)?;
    let out_path = output_dir.join(crate::ops::output_file_name(&seed.name));
    if out_path.symlink_metadata().is_ok() && !opts.overwrite {
        return Err(Error::OutputExists(out_path.display().to_string()));
    }
    fs::create_dir_all(output_dir)?;
    let tmp = output_dir.join(format!(".slys-{}.part", crate::ops::random_suffix()));

    let frag_password = Zeroizing::new(format!("{password}{SPICE}"));
    let total_frags = seed.files.len();
    let result = (|| -> Result<()> {
        let mut out = BufWriter::new(crate::ops::create_exclusive(&tmp)?);
        for (i, name) in seed.files.iter().enumerate() {
            let path = fragments_dir.join(name);
            let data = fs::read(&path).map_err(|e| {
                if e.kind() == std::io::ErrorKind::NotFound {
                    Error::FragmentMissing(name.clone())
                } else {
                    Error::Io(e)
                }
            })?;
            if seed.mode.encrypts(i, total_frags) {
                let plain = decrypt(&data, &frag_password)
                    .map_err(|_| Error::FragmentCorrupted(name.clone()))?;
                out.write_all(&plain)?;
            } else {
                out.write_all(&data)?;
            }
            progress(Progress {
                stage: Stage::Rebuilding,
                done: (i + 1) as u64,
                total: total_frags as u64,
            });
        }
        out.flush()?;
        out.into_inner().map_err(|e| e.into_error())?.sync_all()?;
        Ok(())
    })();
    if let Err(e) = result {
        let _ = fs::remove_file(&tmp);
        return Err(e);
    }
    if let Err(e) = crate::ops::publish(&tmp, &out_path, opts.overwrite) {
        let _ = fs::remove_file(&tmp);
        return Err(e);
    }

    let (deleted, mut warnings) = delete_fragment_files(
        fragments_dir,
        seed.files.iter().map(String::as_str),
        opts.delete_fragments,
        progress,
    );
    // SLYS 1.x used unauthenticated encryption: a wrong or tampered file can not be detected.
    warnings.insert(
        0,
        "This seed uses the old SLYS 1.x format, which cannot verify that the rebuilt file is \
         intact. Check the result, then fragment it again to upgrade to the current format."
            .to_string(),
    );
    Ok(RecomposeReport {
        output: out_path,
        fragments_deleted: deleted,
        warnings,
    })
}
