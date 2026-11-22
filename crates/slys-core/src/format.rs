//! Seed format v2. See documentation/FORMAT.md for the byte layout.
//!
//! Text form:   `SLYS2.<base64url(body)>.<crc32 as 8 hex digits>`
//! The CRC only catches typos while copying and pasting. Security comes from the AEAD tag.

use aes_gcm::aead::{generic_array::GenericArray, Aead, KeyInit, Payload as AeadPayload};
use aes_gcm::Aes256Gcm;
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};

use crate::crypto::{random_bytes, KdfParams, MasterKey, SALT_LEN};
use crate::error::{Error, Result};

pub const MAGIC: &[u8; 4] = b"SLYS";
pub const FORMAT_VERSION: u8 = 2;
pub const TEXT_PREFIX: &str = "SLYS2.";
const KDF_ARGON2ID: u8 = 1;
const NONCE_LEN: usize = 12;
/// magic(4) version(1) kdf_id(1) m(4) t(4) lanes(1) salt(16) nonce(12)
const HEADER_LEN: usize = 4 + 1 + 1 + 4 + 4 + 1 + SALT_LEN + NONCE_LEN;
const MAX_CIPHERTEXT: usize = 16 * 1024 * 1024;

pub const MIN_PARTS: usize = 2;
pub const MAX_PARTS: usize = 10_000;

/// How much of the file is encrypted.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Mode {
    /// Fragments are raw pieces. The seed is still encrypted. Use only for obfuscation.
    Plain = 0,
    /// Only the first and last fragment are encrypted. The rest stays readable. Not recommended.
    Light = 1,
    /// Every fragment is encrypted and authenticated. The default.
    Full = 2,
}

impl Mode {
    fn from_u8(v: u8) -> Result<Mode> {
        match v {
            0 => Ok(Mode::Plain),
            1 => Ok(Mode::Light),
            2 => Ok(Mode::Full),
            _ => Err(Error::SeedMalformed("unknown mode")),
        }
    }

    /// Is fragment `index` (of `total`) encrypted in this mode?
    pub(crate) fn encrypts(self, index: usize, total: usize) -> bool {
        match self {
            Mode::Plain => false,
            Mode::Light => index == 0 || index + 1 == total,
            Mode::Full => true,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FragmentEntry {
    /// File name of the fragment (no directory).
    pub name: String,
    /// Size of the fragment file on disk.
    pub size: u64,
    /// SHA-256 of the fragment file on disk.
    pub sha256: [u8; 32],
}

/// What the seed protects: the decrypted content of a seed.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Payload {
    pub seed_id: [u8; 16],
    pub mode: Mode,
    pub original_name: String,
    pub original_size: u64,
    pub original_sha256: [u8; 32],
    pub fragments: Vec<FragmentEntry>,
}

// ---------------------------------------------------------------- payload (de)serialisation

struct Reader<'a>(&'a [u8]);

impl<'a> Reader<'a> {
    fn take(&mut self, n: usize) -> Result<&'a [u8]> {
        if self.0.len() < n {
            return Err(Error::SeedMalformed("truncated payload"));
        }
        let (a, b) = self.0.split_at(n);
        self.0 = b;
        Ok(a)
    }
    fn arr<const N: usize>(&mut self) -> Result<[u8; N]> {
        Ok(self.take(N)?.try_into().unwrap())
    }
    fn u8(&mut self) -> Result<u8> {
        Ok(self.take(1)?[0])
    }
    fn u16(&mut self) -> Result<u16> {
        Ok(u16::from_be_bytes(self.arr()?))
    }
    fn u32(&mut self) -> Result<u32> {
        Ok(u32::from_be_bytes(self.arr()?))
    }
    fn u64(&mut self) -> Result<u64> {
        Ok(u64::from_be_bytes(self.arr()?))
    }
    fn string(&mut self) -> Result<String> {
        let n = self.u16()? as usize;
        String::from_utf8(self.take(n)?.to_vec()).map_err(|_| Error::SeedMalformed("invalid text"))
    }
}

fn put_string(out: &mut Vec<u8>, s: &str) -> Result<()> {
    let n = u16::try_from(s.len()).map_err(|_| Error::SeedMalformed("name too long"))?;
    out.extend_from_slice(&n.to_be_bytes());
    out.extend_from_slice(s.as_bytes());
    Ok(())
}

impl Payload {
    fn encode(&self) -> Result<Vec<u8>> {
        let mut o = Vec::with_capacity(128 + self.fragments.len() * 64);
        o.extend_from_slice(&self.seed_id);
        o.push(self.mode as u8);
        o.extend_from_slice(&self.original_size.to_be_bytes());
        o.extend_from_slice(&self.original_sha256);
        put_string(&mut o, &self.original_name)?;
        o.extend_from_slice(&(self.fragments.len() as u32).to_be_bytes());
        for f in &self.fragments {
            put_string(&mut o, &f.name)?;
            o.extend_from_slice(&f.size.to_be_bytes());
            o.extend_from_slice(&f.sha256);
        }
        Ok(o)
    }

    fn decode(bytes: &[u8]) -> Result<Payload> {
        let mut r = Reader(bytes);
        let seed_id = r.arr::<16>()?;
        let mode = Mode::from_u8(r.u8()?)?;
        let original_size = r.u64()?;
        let original_sha256 = r.arr::<32>()?;
        let original_name = r.string()?;
        let count = r.u32()? as usize;
        if !(MIN_PARTS..=MAX_PARTS).contains(&count) {
            return Err(Error::SeedMalformed("bad fragment count"));
        }
        let mut fragments = Vec::with_capacity(count);
        for _ in 0..count {
            let name = r.string()?;
            let size = r.u64()?;
            let sha256 = r.arr::<32>()?;
            fragments.push(FragmentEntry { name, size, sha256 });
        }
        if !r.0.is_empty() {
            return Err(Error::SeedMalformed("trailing bytes"));
        }
        Ok(Payload {
            seed_id,
            mode,
            original_name,
            original_size,
            original_sha256,
            fragments,
        })
    }
}

// ---------------------------------------------------------------- sealing / opening

fn header_bytes(params: KdfParams, salt: &[u8; SALT_LEN], nonce: &[u8; NONCE_LEN]) -> Vec<u8> {
    let mut h = Vec::with_capacity(HEADER_LEN);
    h.extend_from_slice(MAGIC);
    h.push(FORMAT_VERSION);
    h.push(KDF_ARGON2ID);
    h.extend_from_slice(&params.m_cost_kib.to_be_bytes());
    h.extend_from_slice(&params.t_cost.to_be_bytes());
    h.push(params.lanes);
    h.extend_from_slice(salt);
    h.extend_from_slice(nonce);
    h
}

/// Seals a payload into the seed text. Returns the text and the master key (so the caller can
/// encrypt the fragments with it without running Argon2 twice).
pub(crate) fn seal(
    payload: &Payload,
    master: &MasterKey,
    params: KdfParams,
    salt: &[u8; SALT_LEN],
) -> Result<String> {
    let nonce: [u8; NONCE_LEN] = random_bytes();
    let header = header_bytes(params, salt, &nonce);
    let key = master.seed_key();
    let cipher = Aes256Gcm::new(GenericArray::from_slice(&*key));
    let ct = cipher
        .encrypt(
            GenericArray::from_slice(&nonce),
            AeadPayload {
                msg: &payload.encode()?,
                aad: &header,
            },
        )
        .map_err(|_| Error::Crypto)?;

    let mut body = header;
    body.extend_from_slice(&(ct.len() as u32).to_be_bytes());
    body.extend_from_slice(&ct);
    Ok(to_text(&body))
}

fn to_text(body: &[u8]) -> String {
    let mut text = String::from(TEXT_PREFIX);
    text.push_str(&URL_SAFE_NO_PAD.encode(body));
    let crc = crc32fast::hash(text.as_bytes());
    text.push('.');
    text.push_str(&format!("{crc:08x}"));
    text
}

/// Strips whitespace (pasted seeds are often wrapped) and checks prefix and CRC.
fn parse_text(text: &str) -> Result<Vec<u8>> {
    let clean: String = text.chars().filter(|c| !c.is_whitespace()).collect();
    let rest = clean
        .strip_prefix(TEXT_PREFIX)
        .ok_or(Error::SeedMalformed("missing SLYS2 prefix"))?;
    let (b64, crc_hex) = rest
        .rsplit_once('.')
        .ok_or(Error::SeedMalformed("missing checksum"))?;
    let expected = u32::from_str_radix(crc_hex, 16).map_err(|_| Error::SeedChecksum)?;
    let actual = crc32fast::hash(&clean.as_bytes()[..TEXT_PREFIX.len() + b64.len()]);
    if expected != actual || crc_hex.len() != 8 {
        return Err(Error::SeedChecksum);
    }
    URL_SAFE_NO_PAD.decode(b64).map_err(|_| Error::SeedChecksum)
}

/// Public information readable without the password.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SeedHeader {
    pub version: u8,
    pub kdf: KdfParams,
}

struct Parsed<'a> {
    header: &'a [u8],
    params: KdfParams,
    salt: [u8; SALT_LEN],
    nonce: [u8; NONCE_LEN],
    ciphertext: &'a [u8],
}

fn split(body: &[u8]) -> Result<Parsed<'_>> {
    if body.len() < HEADER_LEN + 4 || &body[..4] != MAGIC {
        return Err(Error::SeedMalformed("bad magic"));
    }
    if body[4] != FORMAT_VERSION {
        return Err(Error::UnsupportedVersion(body[4]));
    }
    if body[5] != KDF_ARGON2ID {
        return Err(Error::SeedMalformed("unknown KDF"));
    }
    let params = KdfParams {
        m_cost_kib: u32::from_be_bytes(body[6..10].try_into().unwrap()),
        t_cost: u32::from_be_bytes(body[10..14].try_into().unwrap()),
        lanes: body[14],
    };
    let salt: [u8; SALT_LEN] = body[15..15 + SALT_LEN].try_into().unwrap();
    let nonce: [u8; NONCE_LEN] = body[15 + SALT_LEN..HEADER_LEN].try_into().unwrap();
    let ct_len = u32::from_be_bytes(body[HEADER_LEN..HEADER_LEN + 4].try_into().unwrap()) as usize;
    let ciphertext = &body[HEADER_LEN + 4..];
    if ct_len != ciphertext.len() || ct_len > MAX_CIPHERTEXT {
        return Err(Error::SeedMalformed("bad length"));
    }
    Ok(Parsed {
        header: &body[..HEADER_LEN],
        params,
        salt,
        nonce,
        ciphertext,
    })
}

/// Validates the text (prefix, CRC, structure) without needing the password.
pub fn inspect(text: &str) -> Result<SeedHeader> {
    let body = parse_text(text)?;
    let p = split(&body)?;
    p.params.validate()?;
    Ok(SeedHeader {
        version: FORMAT_VERSION,
        kdf: p.params,
    })
}

pub(crate) struct Opened {
    pub payload: Payload,
    pub master: MasterKey,
}

pub(crate) fn open(text: &str, password: &str) -> Result<Opened> {
    let body = parse_text(text)?;
    let p = split(&body)?;
    let master = MasterKey::derive(password, &p.salt, p.params)?;
    let key = master.seed_key();
    let cipher = Aes256Gcm::new(GenericArray::from_slice(&*key));
    let plain = cipher
        .decrypt(
            GenericArray::from_slice(&p.nonce),
            AeadPayload {
                msg: p.ciphertext,
                aad: p.header,
            },
        )
        .map_err(|_| Error::WrongPasswordOrTampered)?;
    // The payload lists names and hashes of your files: do not leave it lying in memory.
    let plain = zeroize::Zeroizing::new(plain);
    let payload = Payload::decode(&plain)?;
    validate_names(&payload)?;
    Ok(Opened { payload, master })
}

/// File names inside a seed must be plain names: no directories, no `..`.
pub(crate) fn safe_name(name: &str) -> bool {
    !name.is_empty() && name != "." && name != ".." && !name.contains(['/', '\\', '\0'])
}

fn validate_names(p: &Payload) -> Result<()> {
    if !safe_name(&p.original_name) || p.fragments.iter().any(|f| !safe_name(&f.name)) {
        return Err(Error::UnsafeName);
    }
    Ok(())
}

pub(crate) fn new_salt() -> [u8; SALT_LEN] {
    random_bytes()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> Payload {
        Payload {
            seed_id: [7; 16],
            mode: Mode::Full,
            original_name: "informe.pdf".into(),
            original_size: 1234,
            original_sha256: [9; 32],
            fragments: (0..3)
                .map(|i| FragmentEntry {
                    name: format!("f{i}.slys"),
                    size: 10 + i,
                    sha256: [i as u8; 32],
                })
                .collect(),
        }
    }

    #[test]
    fn roundtrip() {
        let params = KdfParams::INSECURE_FAST;
        let salt = new_salt();
        let master = MasterKey::derive("pw", &salt, params).unwrap();
        let text = seal(&sample(), &master, params, &salt).unwrap();
        assert!(text.starts_with("SLYS2."));
        let opened = open(&text, "pw").unwrap();
        assert_eq!(opened.payload, sample());
        assert!(matches!(
            open(&text, "other"),
            Err(Error::WrongPasswordOrTampered)
        ));
    }

    #[test]
    fn typo_is_caught_by_crc_before_any_kdf() {
        let params = KdfParams::INSECURE_FAST;
        let salt = new_salt();
        let master = MasterKey::derive("pw", &salt, params).unwrap();
        let text = seal(&sample(), &master, params, &salt).unwrap();
        let mut bytes = text.into_bytes();
        let i = bytes.len() / 2;
        bytes[i] = if bytes[i] == b'A' { b'B' } else { b'A' };
        let bad = String::from_utf8(bytes).unwrap();
        assert!(matches!(inspect(&bad), Err(Error::SeedChecksum)));
        assert!(matches!(open(&bad, "pw"), Err(Error::SeedChecksum)));
    }

    #[test]
    fn whitespace_is_ignored() {
        let params = KdfParams::INSECURE_FAST;
        let salt = new_salt();
        let master = MasterKey::derive("pw", &salt, params).unwrap();
        let text = seal(&sample(), &master, params, &salt).unwrap();
        let wrapped: String = text
            .as_bytes()
            .chunks(40)
            .map(|c| std::str::from_utf8(c).unwrap())
            .collect::<Vec<_>>()
            .join("\n ");
        assert!(open(&wrapped, "pw").is_ok());
    }

    #[test]
    fn unsafe_names_rejected() {
        assert!(!safe_name("../x"));
        assert!(!safe_name("a/b"));
        assert!(!safe_name(".."));
        assert!(safe_name("ok name.pdf"));
    }
}
