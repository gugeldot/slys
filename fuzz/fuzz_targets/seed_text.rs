//! Arbitrary text as a seed (v1 or v2 path). Must never panic, hang or write files.
#![no_main]
use libfuzzer_sys::fuzz_target;
use slys_core::{inspect_seed, recompose, DeleteMode, RecomposeOptions};

fuzz_target!(|data: &[u8]| {
    let text = String::from_utf8_lossy(data);
    let _ = inspect_seed(&text);
    // Only the v2 prefix reaches the (cheap-to-reject) v2 parser; v1 text would run PBKDF2 100k
    // times per input, which makes fuzzing pointless slow.
    if text.trim_start().starts_with("SLYS2.") {
        let dir = std::env::temp_dir().join("slys-fuzz-empty");
        let _ = std::fs::create_dir_all(&dir);
        let opts = RecomposeOptions { overwrite: false, delete_fragments: DeleteMode::Keep };
        let _ = recompose(&text, "pw", &dir, &dir.join("out"), &opts, &mut |_| {});
    }
});
