//! Adversarial tests: what happens when somebody tampers with, truncates, forges or feeds garbage
//! to SLYS. The rule being checked everywhere: the answer is an error, never a panic, never a
//! wrong file on disk, and the fragments are still there afterwards.

use std::fs;
use std::path::{Path, PathBuf};

use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine as _;
use slys_core::{
    fragment, inspect_seed, recompose, DeleteMode, Error, FragmentOptions, KdfParams, Mode,
    RecomposeOptions,
};

fn opts(mode: Mode, parts: usize) -> FragmentOptions {
    FragmentOptions {
        mode,
        parts,
        kdf: KdfParams::INSECURE_FAST,
        delete_original: DeleteMode::Keep,
    }
}

fn ro() -> RecomposeOptions {
    RecomposeOptions {
        overwrite: false,
        delete_fragments: DeleteMode::Keep,
    }
}

fn np() -> impl FnMut(slys_core::Progress) {
    |_| {}
}

struct Fixture {
    _dir: tempfile::TempDir,
    frags: PathBuf,
    out: PathBuf,
    seed: String,
    fragment_files: Vec<PathBuf>,
    data: Vec<u8>,
}

fn fixture(mode: Mode, len: usize, parts: usize) -> Fixture {
    let dir = tempfile::tempdir().unwrap();
    let data: Vec<u8> = (0..len).map(|i| ((i * 31 + 7) % 251) as u8).collect();
    let file = dir.path().join("doc.bin");
    fs::write(&file, &data).unwrap();
    let frags = dir.path().join("frags");
    let r = fragment(&file, &frags, "pw", &opts(mode, parts), &mut np()).unwrap();
    Fixture {
        frags,
        out: dir.path().join("out"),
        seed: r.seed,
        fragment_files: r.fragments,
        data,
        _dir: dir,
    }
}

fn out_is_clean(out: &Path) {
    let leftovers: Vec<_> = fs::read_dir(out)
        .map(|d| d.map(|e| e.unwrap().path()).collect())
        .unwrap_or_default();
    assert!(leftovers.is_empty(), "left behind: {leftovers:?}");
}

/// Recomputes the CRC so a modified seed gets past the typo check and reaches the real
/// cryptographic checks.
fn reseal_text(body: &[u8]) -> String {
    let mut t = String::from("SLYS2.");
    t.push_str(&URL_SAFE_NO_PAD.encode(body));
    let crc = crc32fast::hash(t.as_bytes());
    format!("{t}.{crc:08x}")
}

fn body_of(seed: &str) -> Vec<u8> {
    let rest = seed.strip_prefix("SLYS2.").unwrap();
    let (b64, _) = rest.rsplit_once('.').unwrap();
    URL_SAFE_NO_PAD.decode(b64).unwrap()
}

#[test]
fn flipping_any_bit_of_any_fragment_is_detected_in_every_mode() {
    for mode in [Mode::Full, Mode::Light, Mode::Plain] {
        let fx = fixture(mode, 300, 3);
        for frag in &fx.fragment_files {
            let original = fs::read(frag).unwrap();
            for i in 0..original.len() {
                let mut bad = original.clone();
                bad[i] ^= 0x01;
                fs::write(frag, &bad).unwrap();
                let r = recompose(&fx.seed, "pw", &fx.frags, &fx.out, &ro(), &mut np());
                assert!(
                    r.is_err(),
                    "{mode:?}: byte {i} of {frag:?} changed and nobody noticed"
                );
                out_is_clean(&fx.out);
            }
            fs::write(frag, &original).unwrap();
        }
        // And the untouched set still works.
        let ok = recompose(&fx.seed, "pw", &fx.frags, &fx.out, &ro(), &mut np()).unwrap();
        assert_eq!(fs::read(ok.output).unwrap(), fx.data);
    }
}

#[test]
fn truncating_or_extending_a_fragment_is_detected() {
    for mode in [Mode::Full, Mode::Plain] {
        let fx = fixture(mode, 500, 4);
        for frag in &fx.fragment_files {
            let original = fs::read(frag).unwrap();
            for cut in [0, 1, original.len() / 2, original.len() - 1] {
                fs::write(frag, &original[..cut]).unwrap();
                assert!(recompose(&fx.seed, "pw", &fx.frags, &fx.out, &ro(), &mut np()).is_err());
            }
            let mut longer = original.clone();
            longer.push(0);
            fs::write(frag, &longer).unwrap();
            assert!(recompose(&fx.seed, "pw", &fx.frags, &fx.out, &ro(), &mut np()).is_err());
            fs::write(frag, &original).unwrap();
        }
        out_is_clean(&fx.out);
    }
}

#[test]
fn flipping_any_byte_of_the_seed_is_rejected_even_when_the_crc_is_fixed_up() {
    let fx = fixture(Mode::Full, 400, 3);
    let body = body_of(&fx.seed);
    for i in 0..body.len() {
        for mask in [0x01u8, 0x80] {
            let mut bad = body.clone();
            bad[i] ^= mask;
            // Flipping a high bit of the memory cost asks Argon2 for hundreds of MiB. Those are
            // refused or fail the same way, but would make this loop take minutes; the
            // `hostile_kdf_parameters` test covers oversized values.
            let m = u32::from_be_bytes(bad[6..10].try_into().unwrap());
            if m > 64 * 1024 {
                continue;
            }
            let forged = reseal_text(&bad);
            let r = recompose(&forged, "pw", &fx.frags, &fx.out, &ro(), &mut np());
            assert!(r.is_err(), "seed byte {i} (mask {mask:#x}) was accepted");
            out_is_clean(&fx.out);
        }
    }
}

#[test]
fn every_truncation_of_a_seed_is_an_error_and_never_a_panic() {
    let fx = fixture(Mode::Full, 400, 3);
    for cut in 0..fx.seed.len() {
        let t = &fx.seed[..cut];
        let _ = inspect_seed(t);
        assert!(recompose(t, "pw", &fx.frags, &fx.out, &ro(), &mut np()).is_err());
    }
    out_is_clean(&fx.out);
}

#[test]
fn garbage_input_never_panics() {
    use rand::{Rng, RngCore};
    let mut rng = rand::thread_rng();
    let dir = tempfile::tempdir().unwrap();
    let out = dir.path().join("out");
    for _ in 0..60 {
        let len = rng.gen_range(0..400);
        let mut raw = vec![0u8; len];
        rng.fill_bytes(&mut raw);
        // 1) arbitrary text, 2) valid-looking v2 wrapper around random body, 3) v1-looking base64.
        let candidates = [
            String::from_utf8_lossy(&raw).into_owned(),
            reseal_text(&raw),
            base64::engine::general_purpose::STANDARD.encode(&raw),
            format!("SLYS2.{}", URL_SAFE_NO_PAD.encode(&raw)),
        ];
        for c in candidates {
            let _ = inspect_seed(&c);
            assert!(recompose(&c, "pw", dir.path(), &out, &ro(), &mut np()).is_err());
        }
    }
    out_is_clean(&out);
}

#[test]
fn hostile_kdf_parameters_are_refused_without_doing_the_work() {
    let fx = fixture(Mode::Full, 200, 2);
    let body = body_of(&fx.seed);
    // m = u32::MAX KiB (4 TiB), t = 1_000_000, lanes = 255: would hang or exhaust memory.
    let mut evil = body.clone();
    evil[6..10].copy_from_slice(&u32::MAX.to_be_bytes());
    evil[10..14].copy_from_slice(&1_000_000u32.to_be_bytes());
    evil[14] = 255;
    let text = reseal_text(&evil);
    let started = std::time::Instant::now();
    assert!(matches!(inspect_seed(&text), Err(Error::KdfParams)));
    assert!(matches!(
        recompose(&text, "pw", &fx.frags, &fx.out, &ro(), &mut np()),
        Err(Error::KdfParams)
    ));
    assert!(started.elapsed().as_secs() < 2, "refusal must be immediate");
}

#[test]
fn a_seed_cannot_be_used_with_a_different_password_or_case_changes() {
    let fx = fixture(Mode::Full, 200, 2);
    for pw in ["PW", "pw ", " pw", "p w", "pww", "ｐｗ_"] {
        let r = recompose(&fx.seed, pw, &fx.frags, &fx.out, &ro(), &mut np());
        assert!(
            matches!(r, Err(Error::WrongPasswordOrTampered)),
            "password {pw:?}: {r:?}"
        );
    }
    out_is_clean(&fx.out);
}

#[test]
fn fullwidth_and_plain_forms_of_the_same_password_are_equivalent() {
    // NFKC normalisation: the same text typed on different keyboards/systems must work.
    let dir = tempfile::tempdir().unwrap();
    let file = dir.path().join("a.bin");
    fs::write(&file, vec![9u8; 100]).unwrap();
    let frags = dir.path().join("f");
    let r = fragment(&file, &frags, "pw123", &opts(Mode::Full, 2), &mut np()).unwrap();
    let out = dir.path().join("o");
    recompose(&r.seed, "ｐｗ１２３", &frags, &out, &ro(), &mut np()).unwrap();
}

#[cfg(unix)]
mod symlinks {
    use super::*;
    use std::os::unix::fs::symlink;

    #[test]
    fn recompose_never_writes_through_a_symlink_at_the_output_name() {
        let fx = fixture(Mode::Full, 300, 3);
        fs::create_dir_all(&fx.out).unwrap();
        let victim = fx.out.parent().unwrap().join("victim.txt");
        fs::write(&victim, b"precious").unwrap();
        let planted = fx.out.join("doc.bin");
        symlink(&victim, &planted).unwrap();

        // Without overwrite: refused, victim untouched.
        let r = recompose(&fx.seed, "pw", &fx.frags, &fx.out, &ro(), &mut np());
        assert!(matches!(r, Err(Error::OutputExists(_))), "{r:?}");
        assert_eq!(fs::read(&victim).unwrap(), b"precious");

        // With overwrite: the link itself is replaced, the file it pointed to is not written.
        let mut o = ro();
        o.overwrite = true;
        recompose(&fx.seed, "pw", &fx.frags, &fx.out, &o, &mut np()).unwrap();
        assert_eq!(fs::read(&victim).unwrap(), b"precious");
        assert_eq!(fs::read(&planted).unwrap(), fx.data);
    }

    #[test]
    fn dangling_symlink_at_the_output_name_counts_as_existing() {
        let fx = fixture(Mode::Full, 300, 3);
        fs::create_dir_all(&fx.out).unwrap();
        let target = fx.out.parent().unwrap().join("does-not-exist-yet");
        symlink(&target, fx.out.join("doc.bin")).unwrap();
        let r = recompose(&fx.seed, "pw", &fx.frags, &fx.out, &ro(), &mut np());
        assert!(matches!(r, Err(Error::OutputExists(_))));
        assert!(!target.exists(), "the link target must not be created");
    }

    #[test]
    fn secure_delete_does_not_touch_what_a_symlink_points_to() {
        let dir = tempfile::tempdir().unwrap();
        let victim = dir.path().join("victim");
        fs::write(&victim, b"keep me").unwrap();
        let link = dir.path().join("link");
        symlink(&victim, &link).unwrap();
        slys_core::wipe::secure_delete(&link).unwrap();
        assert!(!link.exists() && link.symlink_metadata().is_err());
        assert_eq!(fs::read(&victim).unwrap(), b"keep me");
    }

    #[test]
    fn a_symlinked_fragment_is_still_integrity_checked() {
        let fx = fixture(Mode::Full, 300, 3);
        let frag = &fx.fragment_files[1];
        let other = frag.with_file_name("elsewhere");
        fs::write(
            &other,
            vec![0u8; fs::metadata(frag).unwrap().len() as usize],
        )
        .unwrap();
        fs::remove_file(frag).unwrap();
        symlink(&other, frag).unwrap();
        assert!(recompose(&fx.seed, "pw", &fx.frags, &fx.out, &ro(), &mut np()).is_err());
        out_is_clean(&fx.out);
    }
}

#[test]
fn fragmenting_never_leaves_temporary_files_on_failure() {
    let dir = tempfile::tempdir().unwrap();
    let file = dir.path().join("tiny.bin");
    fs::write(&file, b"abc").unwrap();
    let frags = dir.path().join("frags");
    // More parts than bytes: refused up front.
    assert!(fragment(&file, &frags, "pw", &opts(Mode::Full, 10), &mut np()).is_err());
    let n = fs::read_dir(&frags).map(|d| d.count()).unwrap_or(0);
    assert_eq!(n, 0);
}
