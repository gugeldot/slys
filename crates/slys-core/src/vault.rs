//! The local list of saved seeds (`seeds.json`).
//!
//! Seeds are already encrypted, so the file does not hold secrets by itself, but the names and
//! timestamps are private, so the file is created with owner-only permissions on Unix.
//! The location is the same as in SLYS 1.x (`<config dir>/slys/seeds.json`) and 1.x entries
//! (`{"nombre": ..., "seed": ...}`) are read transparently.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use serde::{Deserialize, Serialize};

use crate::error::{Error, Result};

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Entry {
    /// Stable identifier. Entries from 1.x get one when the file is first rewritten.
    #[serde(default)]
    pub id: String,
    /// `nombre` is the name used by SLYS 1.x.
    #[serde(alias = "nombre")]
    pub name: String,
    pub seed: String,
    /// Unix time in seconds. 0 for entries from 1.x.
    #[serde(default)]
    pub created_at: u64,
}

/// Default directory: `<config dir>/slys`, overridable with `SLYS_CONFIG_DIR`.
pub fn default_dir() -> Result<PathBuf> {
    if let Some(d) = std::env::var_os("SLYS_CONFIG_DIR") {
        return Ok(PathBuf::from(d));
    }
    dirs::config_dir()
        .map(|d| d.join("slys"))
        .ok_or_else(|| Error::Storage("could not find the user config directory".into()))
}

pub struct Vault {
    dir: PathBuf,
}

pub(crate) fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

/// Atomic write: temp file + rename, owner-only permissions.
pub(crate) fn write_atomic(path: &Path, bytes: &[u8]) -> Result<()> {
    let tmp = path.with_extension("tmp");
    {
        let mut opts = fs::OpenOptions::new();
        opts.write(true).create(true).truncate(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            opts.mode(0o600);
        }
        let mut f = opts.open(&tmp)?;
        f.write_all(bytes)?;
        f.sync_all()?;
    }
    fs::rename(&tmp, path)?;
    Ok(())
}

impl Vault {
    pub fn open_default() -> Result<Vault> {
        Vault::open(default_dir()?)
    }

    pub fn open(dir: impl Into<PathBuf>) -> Result<Vault> {
        let dir = dir.into();
        fs::create_dir_all(&dir)?;
        Ok(Vault { dir })
    }

    pub fn path(&self) -> PathBuf {
        self.dir.join("seeds.json")
    }

    pub fn list(&self) -> Result<Vec<Entry>> {
        let path = self.path();
        if !path.exists() {
            return Ok(vec![]);
        }
        let text = fs::read_to_string(&path)?;
        if text.trim().is_empty() {
            return Ok(vec![]);
        }
        let mut entries: Vec<Entry> = serde_json::from_str(&text)
            .map_err(|e| Error::Storage(format!("seeds.json is not valid: {e}")))?;
        for (i, e) in entries.iter_mut().enumerate() {
            if e.id.is_empty() {
                e.id = format!("legacy-{}", i + 1);
            }
        }
        Ok(entries)
    }

    fn save(&self, entries: &[Entry]) -> Result<()> {
        let json = serde_json::to_vec_pretty(entries).map_err(|e| Error::Storage(e.to_string()))?;
        write_atomic(&self.path(), &json)
    }

    /// Saves a seed. The default name is `fileN`, like in 1.x.
    pub fn add(&self, seed: &str, name: Option<&str>) -> Result<Entry> {
        let mut entries = self.list()?;
        let id: String = {
            let b: [u8; 8] = crate::crypto::random_bytes();
            b.iter().map(|x| format!("{x:02x}")).collect()
        };
        let entry = Entry {
            id,
            name: name
                .map(str::to_string)
                .unwrap_or_else(|| format!("file{}", entries.len() + 1)),
            seed: seed.trim().to_string(),
            created_at: now(),
        };
        entries.push(entry.clone());
        self.save(&entries)?;
        Ok(entry)
    }

    pub fn rename(&self, id: &str, name: &str) -> Result<()> {
        let mut entries = self.list()?;
        let e = entries
            .iter_mut()
            .find(|e| e.id == id)
            .ok_or_else(|| Error::Storage("seed not found".into()))?;
        e.name = name.to_string();
        self.save(&entries)
    }

    /// Removes an entry by id. Returns whether something was removed.
    pub fn remove(&self, id: &str) -> Result<bool> {
        let mut entries = self.list()?;
        let before = entries.len();
        entries.retain(|e| e.id != id);
        let removed = entries.len() != before;
        if removed {
            self.save(&entries)?;
        }
        Ok(removed)
    }

    /// Removes by seed text (what 1.x did).
    pub fn remove_seed(&self, seed: &str) -> Result<bool> {
        let mut entries = self.list()?;
        let before = entries.len();
        entries.retain(|e| e.seed != seed.trim());
        let removed = entries.len() != before;
        if removed {
            self.save(&entries)?;
        }
        Ok(removed)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn add_list_remove_and_legacy_file() {
        let dir = tempfile::tempdir().unwrap();
        let v = Vault::open(dir.path()).unwrap();
        assert!(v.list().unwrap().is_empty());
        let a = v.add("seedA", None).unwrap();
        assert_eq!(a.name, "file1");
        v.add("seedB", Some("tax")).unwrap();
        assert_eq!(v.list().unwrap().len(), 2);
        assert!(v.remove(&a.id).unwrap());
        assert_eq!(v.list().unwrap()[0].name, "tax");

        // a file written by SLYS 1.x
        fs::write(v.path(), r#"[{"nombre":"file1","seed":"abc"}]"#).unwrap();
        let l = v.list().unwrap();
        assert_eq!(l[0].name, "file1");
        assert_eq!(l[0].id, "legacy-1");
    }
}
