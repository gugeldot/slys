//! Key derivation and small crypto helpers.
//!
//! Design (see documentation/FORMAT.md): the password goes through Argon2id once, giving a master key.
//! Independent subkeys (one for the seed, one per fragment) are derived from it with HKDF-SHA256.
//! Nothing here is secret except the password: salts, nonces and parameters are public.

use argon2::{Algorithm, Argon2, Params, Version};
use hkdf::Hkdf;
use sha2::Sha256;
use unicode_normalization::UnicodeNormalization;
use zeroize::Zeroizing;

use crate::error::{Error, Result};

pub const KEY_LEN: usize = 32;
pub const SALT_LEN: usize = 16;

/// Most memory a seed may ask Argon2 for (512 MiB). Seeds can come from other people; this keeps
/// a hostile one from exhausting RAM or CPU. The default is 64 MiB.
pub(crate) const MAX_M_COST_KIB: u32 = 512 * 1024;

/// Argon2id cost parameters. They are stored in the seed, so they can be raised in the future
/// without breaking seeds that already exist.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct KdfParams {
    /// Memory in KiB.
    pub m_cost_kib: u32,
    /// Number of passes.
    pub t_cost: u32,
    /// Degree of parallelism.
    pub lanes: u8,
}

impl Default for KdfParams {
    fn default() -> Self {
        // 64 MiB, 3 passes, 1 lane. Above the OWASP minimum (19 MiB, t=2) and about 0.2-0.4 s
        // on a modern laptop.
        KdfParams {
            m_cost_kib: 64 * 1024,
            t_cost: 3,
            lanes: 1,
        }
    }
}

impl KdfParams {
    /// Cheap parameters, for tests only. Never use for real data.
    pub const INSECURE_FAST: KdfParams = KdfParams {
        m_cost_kib: 8,
        t_cost: 1,
        lanes: 1,
    };

    /// Upper bounds accepted when *reading* a seed, so a crafted seed cannot make us allocate
    /// gigabytes or spin for minutes.
    pub(crate) fn validate(&self) -> Result<()> {
        if self.lanes == 0
            || self.lanes > 16
            || self.t_cost == 0
            || self.t_cost > 16
            || self.m_cost_kib < 8 * self.lanes as u32
            || self.m_cost_kib > MAX_M_COST_KIB
        {
            return Err(Error::KdfParams);
        }
        Ok(())
    }
}

/// Master key. Zeroed on drop.
pub struct MasterKey(Zeroizing<[u8; KEY_LEN]>);

impl MasterKey {
    /// Password -> master key. The password is normalised (NFKC) so the same text typed on
    /// different systems gives the same key.
    pub fn derive(password: &str, salt: &[u8; SALT_LEN], params: KdfParams) -> Result<Self> {
        if password.is_empty() {
            return Err(Error::EmptyPassword);
        }
        params.validate()?;
        let normalised: Zeroizing<String> = Zeroizing::new(password.nfkc().collect());
        let argon_params = Params::new(
            params.m_cost_kib,
            params.t_cost,
            params.lanes as u32,
            Some(KEY_LEN),
        )?;
        let argon = Argon2::new(Algorithm::Argon2id, Version::V0x13, argon_params);
        let mut out = Zeroizing::new([0u8; KEY_LEN]);
        argon
            .hash_password_into(normalised.as_bytes(), salt, &mut *out)
            .map_err(|_| Error::KdfParams)?;
        Ok(MasterKey(out))
    }

    /// Domain-separated subkey (HKDF-SHA256).
    pub fn subkey(&self, info: &[u8]) -> Zeroizing<[u8; KEY_LEN]> {
        let hk = Hkdf::<Sha256>::from_prk(&*self.0).expect("32 bytes is a valid PRK length");
        let mut out = Zeroizing::new([0u8; KEY_LEN]);
        hk.expand(info, &mut *out)
            .expect("32 bytes is a valid HKDF output length");
        out
    }

    pub(crate) fn seed_key(&self) -> Zeroizing<[u8; KEY_LEN]> {
        self.subkey(b"slys v2 seed")
    }

    pub(crate) fn fragment_key(&self, seed_id: &[u8; 16], index: u32) -> Zeroizing<[u8; KEY_LEN]> {
        let mut info = Vec::with_capacity(32);
        info.extend_from_slice(b"slys v2 fragment");
        info.extend_from_slice(seed_id);
        info.extend_from_slice(&index.to_be_bytes());
        self.subkey(&info)
    }
}

pub(crate) fn random_bytes<const N: usize>() -> [u8; N] {
    use rand::RngCore;
    let mut b = [0u8; N];
    rand::rngs::OsRng.fill_bytes(&mut b);
    b
}
