//! A valid seed, but the fuzzer controls the bytes of one fragment file. The only acceptable
//! outcome is an error (the SHA-256 and the AEAD tags must catch everything).
#![no_main]
use libfuzzer_sys::fuzz_target;
use slys_core::{fragment, recompose, DeleteMode, FragmentOptions, KdfParams, Mode, RecomposeOptions};
use std::path::PathBuf;
use std::sync::OnceLock;

struct Fx {
    _dir: tempfile::TempDir,
    frags: PathBuf,
    out: PathBuf,
    seed: String,
    target: PathBuf,
}

fn fx() -> &'static Fx {
    static FX: OnceLock<Fx> = OnceLock::new();
    FX.get_or_init(|| {
        let dir = tempfile::tempdir().unwrap();
        let file = dir.path().join("doc.bin");
        std::fs::write(&file, vec![0x5au8; 2000]).unwrap();
        let frags = dir.path().join("frags");
        let opts = FragmentOptions {
            mode: Mode::Full,
            parts: 3,
            kdf: KdfParams::INSECURE_FAST,
            delete_original: DeleteMode::Keep,
        };
        let r = fragment(&file, &frags, "pw", &opts, &mut |_| {}).unwrap();
        Fx {
            target: r.fragments[1].clone(),
            seed: r.seed,
            out: dir.path().join("out"),
            frags,
            _dir: dir,
        }
    })
}

fuzz_target!(|data: &[u8]| {
    let f = fx();
    std::fs::write(&f.target, data).unwrap();
    let opts = RecomposeOptions { overwrite: true, delete_fragments: DeleteMode::Keep };
    let r = recompose(&f.seed, "pw", &f.frags, &f.out, &opts, &mut |_| {});
    // The original fragment is 2000/3 bytes plus overhead; anything the fuzzer sends can only
    // be accepted if it is byte-identical to it, which would be a (valid) rebuild.
    if let Ok(rep) = r {
        let rebuilt = std::fs::read(rep.output).unwrap();
        assert_eq!(rebuilt, vec![0x5au8; 2000]);
    }
});
