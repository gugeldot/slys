//! Best-effort secure deletion.
//!
//! IMPORTANT LIMITS (also documented in SECURITY.md): overwriting a file in place is not a
//! guarantee on SSDs (wear levelling), copy-on-write or journaling file systems (btrfs, ZFS,
//! APFS, ext4 data=journal), snapshots, or cloud-synced folders. The only reliable protection
//! is full-disk encryption. `secure_delete` does what is realistically possible and says
//! whether it could even try.

use std::fs::{self, OpenOptions};
use std::io::{Seek, SeekFrom, Write};
use std::path::Path;

use rand::RngCore;

use crate::error::Result;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum WipeOutcome {
    /// Contents were overwritten (random, then zeros), flushed, truncated and unlinked.
    Overwritten,
    /// Only unlinked (for example a symlink, which is removed without following it).
    Unlinked,
}

pub fn secure_delete(path: &Path) -> Result<WipeOutcome> {
    let meta = fs::symlink_metadata(path)?;
    if !meta.is_file() {
        fs::remove_file(path)?;
        return Ok(WipeOutcome::Unlinked);
    }

    let len = meta.len();
    {
        let mut opts = OpenOptions::new();
        opts.write(true);
        // Never follow a symlink swapped in between the check above and this open.
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            opts.custom_flags(libc::O_NOFOLLOW);
        }
        let mut f = opts.open(path)?;
        if !f.metadata()?.is_file() {
            return Err(crate::error::Error::Storage("not a regular file".into()));
        }
        let mut buf = vec![0u8; 1024 * 1024];
        // pass 1: random data
        overwrite(&mut f, len, &mut buf, true)?;
        // pass 2: zeros
        overwrite(&mut f, len, &mut buf, false)?;
        f.set_len(0)?;
        f.sync_all()?;
    }

    // Rename to a random name first, so the original name does not linger in directory entries.
    let random_name: String = {
        let b: [u8; 8] = crate::crypto::random_bytes();
        b.iter().map(|x| format!("{x:02x}")).collect()
    };
    let target = path.with_file_name(random_name);
    let remove_path = if fs::rename(path, &target).is_ok() {
        target
    } else {
        path.to_path_buf()
    };
    fs::remove_file(remove_path)?;
    Ok(WipeOutcome::Overwritten)
}

fn overwrite(f: &mut std::fs::File, len: u64, buf: &mut [u8], random: bool) -> std::io::Result<()> {
    f.seek(SeekFrom::Start(0))?;
    let mut left = len;
    while left > 0 {
        let n = left.min(buf.len() as u64) as usize;
        if random {
            rand::rngs::OsRng.fill_bytes(&mut buf[..n]);
        } else {
            buf[..n].fill(0);
        }
        f.write_all(&buf[..n])?;
        left -= n as u64;
    }
    f.flush()?;
    f.sync_all()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn removes_file() {
        let dir = tempfile::tempdir().unwrap();
        let p = dir.path().join("secret.txt");
        fs::write(&p, vec![42u8; 3_000_000]).unwrap();
        assert_eq!(secure_delete(&p).unwrap(), WipeOutcome::Overwritten);
        assert!(!p.exists());
        assert_eq!(fs::read_dir(dir.path()).unwrap().count(), 0, "no leftovers");
    }
}
