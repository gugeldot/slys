//! Encrypted fragment files: a chunked AES-256-GCM stream (STREAM construction, BE32).
//!
//! Layout: `"SLYF" | 0x01 | nonce_prefix[7] | chunk*`
//! Every chunk is `CHUNK_SIZE` plaintext bytes (the last one may be shorter) plus a 16-byte tag.
//! The STREAM construction authenticates chunk order and marks the last chunk, so reordering,
//! dropping or truncating chunks is detected. The associated data binds the fragment to its
//! seed and its position.

use std::io::{self, Read, Write};

use aes_gcm::aead::generic_array::GenericArray;
use aes_gcm::aead::stream::{DecryptorBE32, EncryptorBE32};
use aes_gcm::{Aes256Gcm, KeyInit};
use sha2::{Digest, Sha256};

use crate::crypto::random_bytes;
use crate::error::{Error, Result};

const MAGIC: &[u8; 4] = b"SLYF";
const VERSION: u8 = 1;
const PREFIX_LEN: usize = 7;
pub const HEADER_LEN: usize = 4 + 1 + PREFIX_LEN;
pub const CHUNK_SIZE: usize = 64 * 1024;
const TAG_LEN: usize = 16;

pub(crate) fn aad(seed_id: &[u8; 16], index: u32) -> [u8; 20] {
    let mut a = [0u8; 20];
    a[..16].copy_from_slice(seed_id);
    a[16..].copy_from_slice(&index.to_be_bytes());
    a
}

/// Reads until `buf` is full or EOF. Returns the number of bytes read.
fn read_full<R: Read>(r: &mut R, buf: &mut [u8]) -> io::Result<usize> {
    let mut n = 0;
    while n < buf.len() {
        match r.read(&mut buf[n..]) {
            Ok(0) => break,
            Ok(k) => n += k,
            Err(e) if e.kind() == io::ErrorKind::Interrupted => {}
            Err(e) => return Err(e),
        }
    }
    Ok(n)
}

/// Encrypts exactly `len` bytes from `input` into `out`.
pub(crate) fn encrypt_stream<R: Read, W: Write>(
    input: &mut R,
    out: &mut W,
    key: &[u8; 32],
    aad: &[u8],
    len: u64,
    on_bytes: &mut dyn FnMut(u64),
) -> Result<()> {
    let prefix: [u8; PREFIX_LEN] = random_bytes();
    out.write_all(MAGIC)?;
    out.write_all(&[VERSION])?;
    out.write_all(&prefix)?;

    let mut enc = EncryptorBE32::from_aead(
        Aes256Gcm::new(GenericArray::from_slice(key)),
        GenericArray::from_slice(&prefix),
    );
    let mut remaining = len;
    let mut buf: Vec<u8> = Vec::with_capacity(CHUNK_SIZE + TAG_LEN);
    while remaining > CHUNK_SIZE as u64 {
        buf.resize(CHUNK_SIZE, 0);
        input.read_exact(&mut buf)?;
        enc.encrypt_next_in_place(aad, &mut buf)
            .map_err(|_| Error::Crypto)?;
        out.write_all(&buf)?;
        remaining -= CHUNK_SIZE as u64;
        on_bytes(CHUNK_SIZE as u64);
    }
    buf.resize(remaining as usize, 0);
    input.read_exact(&mut buf)?;
    enc.encrypt_last_in_place(aad, &mut buf)
        .map_err(|_| Error::Crypto)?;
    out.write_all(&buf)?;
    on_bytes(remaining);
    Ok(())
}

/// Decrypts a whole fragment stream into `out`. Any modification returns `Err(Crypto)`; the
/// caller maps it to a user-facing error that names the fragment.
pub(crate) fn decrypt_stream<R: Read, W: Write>(
    input: &mut R,
    out: &mut W,
    key: &[u8; 32],
    aad: &[u8],
    on_bytes: &mut dyn FnMut(u64),
) -> Result<()> {
    let mut header = [0u8; HEADER_LEN];
    if read_full(input, &mut header)? != HEADER_LEN || &header[..4] != MAGIC || header[4] != VERSION
    {
        return Err(Error::Crypto);
    }
    let mut dec = DecryptorBE32::from_aead(
        Aes256Gcm::new(GenericArray::from_slice(key)),
        GenericArray::from_slice(&header[5..]),
    );

    let mut cur: Vec<u8> = vec![0; CHUNK_SIZE + TAG_LEN];
    let n = read_full(input, &mut cur)?;
    cur.truncate(n);
    if cur.len() < TAG_LEN {
        return Err(Error::Crypto);
    }
    loop {
        let mut next: Vec<u8> = vec![0; CHUNK_SIZE + TAG_LEN];
        let n = read_full(input, &mut next)?;
        next.truncate(n);
        if next.is_empty() {
            dec.decrypt_last_in_place(aad, &mut cur)
                .map_err(|_| Error::Crypto)?;
            out.write_all(&cur)?;
            on_bytes(cur.len() as u64);
            return Ok(());
        }
        dec.decrypt_next_in_place(aad, &mut cur)
            .map_err(|_| Error::Crypto)?;
        out.write_all(&cur)?;
        on_bytes(cur.len() as u64);
        cur = next;
    }
}

/// Wraps a writer and hashes / counts everything written through it.
pub(crate) struct HashWriter<W> {
    pub inner: W,
    pub hasher: Sha256,
    pub written: u64,
}

impl<W: Write> HashWriter<W> {
    pub fn new(inner: W) -> Self {
        HashWriter {
            inner,
            hasher: Sha256::new(),
            written: 0,
        }
    }
    pub fn finish(self) -> (W, [u8; 32], u64) {
        (self.inner, self.hasher.finalize().into(), self.written)
    }
}

impl<W: Write> Write for HashWriter<W> {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        let n = self.inner.write(buf)?;
        self.hasher.update(&buf[..n]);
        self.written += n as u64;
        Ok(n)
    }
    fn flush(&mut self) -> io::Result<()> {
        self.inner.flush()
    }
}

/// Wraps a reader and hashes / counts everything read through it.
pub(crate) struct HashReader<R> {
    pub inner: R,
    pub hasher: Sha256,
    pub read: u64,
}

impl<R: Read> HashReader<R> {
    pub fn new(inner: R) -> Self {
        HashReader {
            inner,
            hasher: Sha256::new(),
            read: 0,
        }
    }
    pub fn finish(self) -> ([u8; 32], u64) {
        (self.hasher.finalize().into(), self.read)
    }
}

impl<R: Read> Read for HashReader<R> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let n = self.inner.read(buf)?;
        self.hasher.update(&buf[..n]);
        self.read += n as u64;
        Ok(n)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn roundtrip(len: usize) {
        let key = [5u8; 32];
        let data: Vec<u8> = (0..len).map(|i| (i * 31 % 251) as u8).collect();
        let mut enc = Vec::new();
        encrypt_stream(
            &mut &data[..],
            &mut enc,
            &key,
            b"aad",
            len as u64,
            &mut |_| {},
        )
        .unwrap();
        let mut dec = Vec::new();
        decrypt_stream(&mut &enc[..], &mut dec, &key, b"aad", &mut |_| {}).unwrap();
        assert_eq!(dec, data, "len {len}");
    }

    #[test]
    fn roundtrips_around_chunk_boundaries() {
        for len in [
            1,
            2,
            CHUNK_SIZE - 1,
            CHUNK_SIZE,
            CHUNK_SIZE + 1,
            3 * CHUNK_SIZE,
            3 * CHUNK_SIZE + 17,
        ] {
            roundtrip(len);
        }
    }

    #[test]
    fn detects_tamper_truncation_and_wrong_aad() {
        let key = [5u8; 32];
        let len = 3 * CHUNK_SIZE + 5;
        let data = vec![1u8; len];
        let mut enc = Vec::new();
        encrypt_stream(
            &mut &data[..],
            &mut enc,
            &key,
            b"aad",
            len as u64,
            &mut |_| {},
        )
        .unwrap();
        let try_dec = |bytes: &[u8], aad: &[u8]| {
            let mut out = Vec::new();
            decrypt_stream(&mut &bytes[..], &mut out, &key, aad, &mut |_| {})
        };
        assert!(try_dec(&enc, b"aad").is_ok());
        assert!(try_dec(&enc, b"other").is_err());
        let mut flipped = enc.clone();
        flipped[HEADER_LEN + 100] ^= 1;
        assert!(try_dec(&flipped, b"aad").is_err());
        // drop the last chunk entirely: must fail, not silently return a shorter file
        let cut = HEADER_LEN + 3 * (CHUNK_SIZE + TAG_LEN);
        assert!(try_dec(&enc[..cut], b"aad").is_err());
        assert!(try_dec(&enc[..enc.len() - 1], b"aad").is_err());
    }
}
