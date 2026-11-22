use std::fs;
use std::path::{Path, PathBuf};

use slys_core::{
    fragment, inspect_seed, recompose, DeleteMode, Error, FragmentOptions, KdfParams, Mode,
    RecomposeOptions, SeedInfo,
};

fn opts(mode: Mode, parts: usize) -> FragmentOptions {
    FragmentOptions {
        mode,
        parts,
        kdf: KdfParams::INSECURE_FAST,
        delete_original: DeleteMode::Keep,
    }
}

fn no_progress() -> impl FnMut(slys_core::Progress) {
    |_| {}
}

fn sample(dir: &Path, name: &str, len: usize) -> (PathBuf, Vec<u8>) {
    let data: Vec<u8> = (0..len).map(|i| ((i * 7919) % 251) as u8).collect();
    let p = dir.join(name);
    fs::write(&p, &data).unwrap();
    (p, data)
}

fn ro() -> RecomposeOptions {
    RecomposeOptions {
        overwrite: false,
        delete_fragments: DeleteMode::Keep,
    }
}

#[test]
fn roundtrip_every_mode_and_size() {
    for mode in [Mode::Full, Mode::Light, Mode::Plain] {
        for len in [7usize, 1000, 200_000, 3 * 65_536 + 5] {
            let dir = tempfile::tempdir().unwrap();
            let (file, data) = sample(dir.path(), "doc.bin", len);
            let frags = dir.path().join("frags");
            let parts = 5.min(len);
            let r = fragment(&file, &frags, "pw", &opts(mode, parts), &mut no_progress()).unwrap();
            assert_eq!(r.fragments.len(), parts);
            assert!(matches!(
                inspect_seed(&r.seed).unwrap(),
                SeedInfo::V2 { .. }
            ));

            let out = dir.path().join("out");
            let rep = recompose(&r.seed, "pw", &frags, &out, &ro(), &mut no_progress()).unwrap();
            assert_eq!(fs::read(rep.output).unwrap(), data, "{mode:?} {len}");
        }
    }
}

#[test]
fn full_mode_leaves_nothing_readable_but_plain_does() {
    let dir = tempfile::tempdir().unwrap();
    let marker = b"TOP-SECRET-MARKER-TOP-SECRET-MARKER".repeat(50);
    let file = dir.path().join("m.txt");
    fs::write(&file, &marker).unwrap();
    for (mode, expect_leak) in [(Mode::Full, false), (Mode::Plain, true)] {
        let frags = dir.path().join(format!("f{mode:?}"));
        fragment(&file, &frags, "pw", &opts(mode, 4), &mut no_progress()).unwrap();
        let all: Vec<u8> = fs::read_dir(&frags)
            .unwrap()
            .flat_map(|e| fs::read(e.unwrap().path()).unwrap())
            .collect();
        let leaked = all.windows(20).any(|w| w == &marker[..20]);
        assert_eq!(leaked, expect_leak, "{mode:?}");
    }
}

#[test]
fn wrong_password_does_not_write_anything() {
    let dir = tempfile::tempdir().unwrap();
    let (file, _) = sample(dir.path(), "a.bin", 5000);
    let frags = dir.path().join("frags");
    let r = fragment(
        &file,
        &frags,
        "right",
        &opts(Mode::Full, 3),
        &mut no_progress(),
    )
    .unwrap();
    let out = dir.path().join("out");
    let e = recompose(&r.seed, "wrong", &frags, &out, &ro(), &mut no_progress()).unwrap_err();
    assert!(matches!(e, Error::WrongPasswordOrTampered));
    assert!(!out.join("a.bin").exists());
}

#[test]
fn tampered_fragment_is_detected_and_nothing_is_left_behind() {
    for mode in [Mode::Full, Mode::Plain] {
        let dir = tempfile::tempdir().unwrap();
        let (file, _) = sample(dir.path(), "a.bin", 20_000);
        let frags = dir.path().join("frags");
        let r = fragment(&file, &frags, "pw", &opts(mode, 4), &mut no_progress()).unwrap();
        let victim = &r.fragments[1];
        let mut bytes = fs::read(victim).unwrap();
        let mid = bytes.len() / 2;
        bytes[mid] ^= 0x01;
        fs::write(victim, bytes).unwrap();

        let out = dir.path().join("out");
        let e = recompose(
            &r.seed,
            "pw",
            &frags,
            &out,
            &RecomposeOptions {
                overwrite: false,
                delete_fragments: DeleteMode::Delete,
            },
            &mut no_progress(),
        )
        .unwrap_err();
        assert!(matches!(e, Error::FragmentCorrupted(_)), "{mode:?}: {e}");
        assert_eq!(fs::read_dir(&out).unwrap().count(), 0, "no partial output");
        assert_eq!(
            fs::read_dir(&frags).unwrap().count(),
            4,
            "fragments must survive a failure"
        );
    }
}

#[test]
fn swapped_and_missing_fragments_are_detected() {
    let dir = tempfile::tempdir().unwrap();
    let (file, _) = sample(dir.path(), "a.bin", 20_000);
    let frags = dir.path().join("frags");
    let r = fragment(
        &file,
        &frags,
        "pw",
        &opts(Mode::Full, 4),
        &mut no_progress(),
    )
    .unwrap();
    let out = dir.path().join("out");

    // swap contents of two fragments
    let (a, b) = (&r.fragments[0], &r.fragments[2]);
    let (da, db) = (fs::read(a).unwrap(), fs::read(b).unwrap());
    fs::write(a, &db).unwrap();
    fs::write(b, &da).unwrap();
    assert!(matches!(
        recompose(&r.seed, "pw", &frags, &out, &ro(), &mut no_progress()).unwrap_err(),
        Error::FragmentCorrupted(_)
    ));
    fs::write(a, &da).unwrap();
    fs::write(b, &db).unwrap();

    // missing
    fs::remove_file(&r.fragments[3]).unwrap();
    assert!(matches!(
        recompose(&r.seed, "pw", &frags, &out, &ro(), &mut no_progress()).unwrap_err(),
        Error::FragmentMissing(_)
    ));
}

#[test]
fn fragments_of_another_seed_do_not_mix() {
    let dir = tempfile::tempdir().unwrap();
    let (file, _) = sample(dir.path(), "a.bin", 9000);
    let f1 = dir.path().join("f1");
    let f2 = dir.path().join("f2");
    let r1 = fragment(&file, &f1, "pw", &opts(Mode::Full, 3), &mut no_progress()).unwrap();
    let r2 = fragment(&file, &f2, "pw", &opts(Mode::Full, 3), &mut no_progress()).unwrap();
    // put a fragment of seed 2 under the name seed 1 expects
    fs::copy(&r2.fragments[0], &r1.fragments[0]).unwrap();
    let e = recompose(
        &r1.seed,
        "pw",
        &f1,
        &dir.path().join("o"),
        &ro(),
        &mut no_progress(),
    )
    .unwrap_err();
    assert!(matches!(e, Error::FragmentCorrupted(_)));
}

#[test]
fn originals_and_fragments_are_removed_only_on_success() {
    let dir = tempfile::tempdir().unwrap();
    let (file, data) = sample(dir.path(), "a.bin", 12_345);
    let frags = dir.path().join("frags");
    let o = FragmentOptions {
        delete_original: DeleteMode::Wipe,
        ..opts(Mode::Full, 5)
    };
    let r = fragment(&file, &frags, "pw", &o, &mut no_progress()).unwrap();
    assert!(r.original_deleted);
    assert!(!file.exists());

    let out = dir.path().join("out");
    let rep = recompose(
        &r.seed,
        "pw",
        &frags,
        &out,
        &RecomposeOptions {
            overwrite: false,
            delete_fragments: DeleteMode::Wipe,
        },
        &mut no_progress(),
    )
    .unwrap();
    assert!(rep.fragments_deleted);
    assert_eq!(fs::read_dir(&frags).unwrap().count(), 0);
    assert_eq!(fs::read(rep.output).unwrap(), data);
}

#[test]
fn does_not_overwrite_unless_asked() {
    let dir = tempfile::tempdir().unwrap();
    let (file, _) = sample(dir.path(), "a.bin", 3000);
    let frags = dir.path().join("frags");
    let r = fragment(
        &file,
        &frags,
        "pw",
        &opts(Mode::Full, 3),
        &mut no_progress(),
    )
    .unwrap();
    // the original `a.bin` still exists in dir; rebuild into the same dir
    let e = recompose(&r.seed, "pw", &frags, dir.path(), &ro(), &mut no_progress()).unwrap_err();
    assert!(matches!(e, Error::OutputExists(_)));
    let ok = recompose(
        &r.seed,
        "pw",
        &frags,
        dir.path(),
        &RecomposeOptions {
            overwrite: true,
            ..ro()
        },
        &mut no_progress(),
    );
    assert!(ok.is_ok());
}

#[test]
fn input_validation() {
    let dir = tempfile::tempdir().unwrap();
    let (file, _) = sample(dir.path(), "a.bin", 3);
    let out = dir.path().join("o");
    assert!(matches!(
        fragment(&file, &out, "pw", &opts(Mode::Full, 5), &mut no_progress()),
        Err(Error::TooManyParts { .. })
    ));
    assert!(matches!(
        fragment(&file, &out, "pw", &opts(Mode::Full, 1), &mut no_progress()),
        Err(Error::InvalidParts { .. })
    ));
    assert!(matches!(
        fragment(&file, &out, "", &opts(Mode::Full, 2), &mut no_progress()),
        Err(Error::EmptyPassword)
    ));
    assert!(matches!(
        fragment(
            &dir.path().join("nope"),
            &out,
            "pw",
            &opts(Mode::Full, 2),
            &mut no_progress()
        ),
        Err(Error::InputNotFound(_))
    ));
}

// ---------------------------------------------------------------- SLYS 1.x compatibility

const V1_PASSWORD: &str = "pässw0rd";

fn v1_dir(name: &str) -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/fixtures/v1")
        .join(name)
}

#[test]
fn rebuilds_seeds_made_by_slys_1_5_1() {
    let original = fs::read(v1_dir("original.bin")).unwrap();
    for mode in ["Partial", "Total", "None"] {
        let seed = fs::read_to_string(v1_dir(&format!("{mode}.seed"))).unwrap();
        assert_eq!(inspect_seed(&seed).unwrap(), SeedInfo::Legacy);
        let out = tempfile::tempdir().unwrap();
        let rep = recompose(
            &seed,
            V1_PASSWORD,
            &v1_dir(mode),
            out.path(),
            &ro(),
            &mut no_progress(),
        )
        .unwrap();
        // 1.x stored the original file name, which was `sample_<mode>.bin`
        assert_eq!(fs::read(&rep.output).unwrap(), original, "{mode}");
    }
}

#[test]
fn legacy_wrong_password_is_an_error() {
    let seed = fs::read_to_string(v1_dir("Total.seed")).unwrap();
    let out = tempfile::tempdir().unwrap();
    let e = recompose(
        &seed,
        "nope",
        &v1_dir("Total"),
        out.path(),
        &ro(),
        &mut no_progress(),
    )
    .unwrap_err();
    assert!(matches!(e, Error::LegacyDecrypt));
    assert_eq!(fs::read_dir(out.path()).unwrap().count(), 0);
}

#[test]
fn legacy_corrupted_fragment_is_an_error_not_garbage() {
    // 1.x wrote the ciphertext into the output when a fragment failed to decrypt.
    let seed = fs::read_to_string(v1_dir("Total.seed")).unwrap();
    let work = tempfile::tempdir().unwrap();
    for e in fs::read_dir(v1_dir("Total")).unwrap() {
        let e = e.unwrap();
        fs::copy(e.path(), work.path().join(e.file_name())).unwrap();
    }
    let first = fs::read_dir(work.path())
        .unwrap()
        .next()
        .unwrap()
        .unwrap()
        .path();
    let mut b = fs::read(&first).unwrap();
    let n = b.len();
    b.truncate(n - 3);
    fs::write(&first, b).unwrap();
    let out = tempfile::tempdir().unwrap();
    let r = recompose(
        &seed,
        V1_PASSWORD,
        work.path(),
        out.path(),
        &ro(),
        &mut no_progress(),
    );
    assert!(r.is_err());
    assert_eq!(fs::read_dir(out.path()).unwrap().count(), 0);
}
