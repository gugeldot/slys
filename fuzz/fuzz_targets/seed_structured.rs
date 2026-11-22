//! Random bytes wrapped in a *valid* v2 envelope (prefix + base64 + correct CRC), so the fuzzer
//! gets past the typo check and exercises the binary parser and the KDF-parameter checks.
#![no_main]
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine as _;
use libfuzzer_sys::fuzz_target;
use slys_core::{inspect_seed, recompose, DeleteMode, RecomposeOptions};

fuzz_target!(|data: &[u8]| {
    let mut t = String::from("SLYS2.");
    t.push_str(&URL_SAFE_NO_PAD.encode(data));
    let crc = crc32fast::hash(t.as_bytes());
    let text = format!("{t}.{crc:08x}");
    let _ = inspect_seed(&text);
    let dir = std::env::temp_dir().join("slys-fuzz-empty");
    let _ = std::fs::create_dir_all(&dir);
    let opts = RecomposeOptions { overwrite: false, delete_fragments: DeleteMode::Keep };
    let _ = recompose(&text, "pw", &dir, &dir.join("out"), &opts, &mut |_| {});
});
