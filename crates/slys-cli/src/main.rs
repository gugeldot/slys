//! `slys`: command-line front end for slys-core.
//!
//! Passwords are NEVER taken as command-line arguments (they would show up in `ps` and in the
//! shell history). Use the interactive prompt, `--password-stdin`, or the SLYS_PASSWORD
//! environment variable (handy for tests and scripts).

use std::io::{self, Read};
use std::path::PathBuf;
use std::process::ExitCode;

use clap::{Args, Parser, Subcommand, ValueEnum};
use indicatif::{ProgressBar, ProgressStyle};
use slys_core::inactivity::{Inactivity, Status};
use slys_core::vault::Vault;
use slys_core::{
    DeleteMode, FragmentOptions, KdfParams, Mode, Progress, RecomposeOptions, SeedInfo, Stage,
};
use zeroize::Zeroizing;

#[derive(Parser)]
#[command(
    name = "slys",
    version,
    about = "Fragment and encrypt files. Rebuild them with a seed and a password."
)]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Args)]
struct PasswordArgs {
    /// Read the password from the first line of stdin instead of prompting.
    #[arg(long)]
    password_stdin: bool,
}

#[derive(Copy, Clone, ValueEnum)]
enum ModeArg {
    /// Every fragment encrypted and authenticated (default).
    Full,
    /// Only the first and last fragment encrypted. Not recommended.
    Light,
    /// No fragment encrypted. Obfuscation only.
    Plain,
}

#[derive(Copy, Clone, ValueEnum)]
enum DeleteArg {
    Keep,
    Delete,
    Wipe,
}

impl From<DeleteArg> for DeleteMode {
    fn from(d: DeleteArg) -> Self {
        match d {
            DeleteArg::Keep => DeleteMode::Keep,
            DeleteArg::Delete => DeleteMode::Delete,
            DeleteArg::Wipe => DeleteMode::Wipe,
        }
    }
}

#[derive(Subcommand)]
enum Cmd {
    /// Split FILE into encrypted fragments. Prints the seed on stdout.
    Frag {
        file: PathBuf,
        /// Directory for the fragments.
        #[arg(short, long)]
        out: PathBuf,
        #[arg(short = 'n', long, default_value_t = 5)]
        parts: usize,
        #[arg(short, long, value_enum, default_value_t = ModeArg::Full)]
        mode: ModeArg,
        /// What to do with the original after the fragments were verified.
        #[arg(long, value_enum, default_value_t = DeleteArg::Wipe)]
        original: DeleteArg,
        /// Save the seed in the local seed list.
        #[arg(long)]
        save: bool,
        #[command(flatten)]
        pw: PasswordArgs,
    },
    /// Rebuild a file. SEED is the seed text, or @FILE to read it from a file.
    Compose {
        seed: String,
        /// Directory holding the fragments.
        #[arg(short, long)]
        fragments: PathBuf,
        /// Directory for the rebuilt file.
        #[arg(short, long)]
        out: PathBuf,
        #[arg(long, value_enum, default_value_t = DeleteArg::Wipe)]
        delete_fragments: DeleteArg,
        #[arg(long)]
        overwrite: bool,
        #[command(flatten)]
        pw: PasswordArgs,
    },
    /// Check a seed (typos, version) without a password.
    Inspect { seed: String },
    /// Manage the local seed list.
    Seeds {
        #[command(subcommand)]
        cmd: SeedsCmd,
    },
    /// Opt-in wipe of the local seed list after a period of inactivity.
    Inactivity {
        #[command(subcommand)]
        cmd: InactivityCmd,
    },
    /// Show version information.
    Version,
}

#[derive(Subcommand)]
enum SeedsCmd {
    List,
    Add {
        seed: String,
        #[arg(long)]
        name: Option<String>,
    },
    Remove {
        id: String,
    },
}

#[derive(Subcommand)]
enum InactivityCmd {
    Status,
    Enable {
        #[arg(long, default_value_t = 90)]
        days: u32,
    },
    Disable,
    /// Wipe now if the deadline passed (the app calls this at startup).
    Enforce,
}

fn read_password(args: &PasswordArgs, confirm: bool) -> io::Result<Zeroizing<String>> {
    if let Ok(p) = std::env::var("SLYS_PASSWORD") {
        return Ok(Zeroizing::new(p));
    }
    if args.password_stdin {
        let mut s = String::new();
        io::stdin().read_to_string(&mut s)?;
        let line = s.lines().next().unwrap_or("").to_string();
        return Ok(Zeroizing::new(line));
    }
    let p = Zeroizing::new(rpassword::prompt_password("Password: ")?);
    if confirm {
        let again = Zeroizing::new(rpassword::prompt_password("Repeat password: ")?);
        if *p != *again {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "passwords do not match",
            ));
        }
    }
    Ok(p)
}

fn seed_arg(s: &str) -> io::Result<String> {
    match s.strip_prefix('@') {
        Some(path) => std::fs::read_to_string(path),
        None => Ok(s.to_string()),
    }
}

fn bar() -> (ProgressBar, impl FnMut(Progress)) {
    let pb = ProgressBar::new(100);
    pb.set_style(ProgressStyle::with_template("{msg:<12} [{bar:30}] {percent}%").unwrap());
    let pb2 = pb.clone();
    let f = move |p: Progress| {
        let msg = match p.stage {
            Stage::Deriving => "Deriving key",
            Stage::Encrypting => "Encrypting",
            Stage::Verifying => "Verifying",
            Stage::Rebuilding => "Rebuilding",
            Stage::Cleaning => "Cleaning",
        };
        pb2.set_message(msg);
        if let Some(pct) = (p.done * 100).checked_div(p.total) {
            pb2.set_position(pct);
        }
    };
    (pb, f)
}

fn run(cli: Cli) -> Result<(), Box<dyn std::error::Error>> {
    match cli.cmd {
        Cmd::Frag {
            file,
            out,
            parts,
            mode,
            original,
            save,
            pw,
        } => {
            let password = read_password(
                &pw,
                std::env::var("SLYS_PASSWORD").is_err() && !pw.password_stdin,
            )?;
            let mode = match mode {
                ModeArg::Full => Mode::Full,
                ModeArg::Light => Mode::Light,
                ModeArg::Plain => Mode::Plain,
            };
            if mode != Mode::Full {
                eprintln!("warning: this mode leaves part of the file readable. Use `full` for real protection.");
            }
            let opts = FragmentOptions {
                mode,
                parts,
                kdf: kdf_from_env(),
                delete_original: original.into(),
            };
            let (pb, mut tick) = bar();
            let report = slys_core::fragment(&file, &out, &password, &opts, &mut tick)?;
            pb.finish_and_clear();
            if save {
                Vault::open_default()?.add(&report.seed, None)?;
            }
            for w in &report.warnings {
                eprintln!("warning: {w}");
            }
            eprintln!(
                "{} fragments written to {}",
                report.fragments.len(),
                out.display()
            );
            println!("{}", report.seed);
        }
        Cmd::Compose {
            seed,
            fragments,
            out,
            delete_fragments,
            overwrite,
            pw,
        } => {
            let password = read_password(&pw, false)?;
            let opts = RecomposeOptions {
                overwrite,
                delete_fragments: delete_fragments.into(),
            };
            let (pb, mut tick) = bar();
            let report = slys_core::recompose(
                &seed_arg(&seed)?,
                &password,
                &fragments,
                &out,
                &opts,
                &mut tick,
            )?;
            pb.finish_and_clear();
            for w in &report.warnings {
                eprintln!("warning: {w}");
            }
            println!("{}", report.output.display());
        }
        Cmd::Inspect { seed } => match slys_core::inspect_seed(&seed_arg(&seed)?)? {
            SeedInfo::V2 { kdf } => println!(
                "valid seed, format 2 (Argon2id {} MiB, t={}, lanes={}). Checksum OK.",
                kdf.m_cost_kib / 1024,
                kdf.t_cost,
                kdf.lanes
            ),
            SeedInfo::Legacy => println!("seed from SLYS 1.x (read-only support, no checksum)"),
        },
        Cmd::Seeds { cmd } => {
            let v = Vault::open_default()?;
            match cmd {
                SeedsCmd::List => {
                    for e in v.list()? {
                        println!(
                            "{}\t{}\t{}…",
                            e.id,
                            e.name,
                            e.seed.chars().take(24).collect::<String>()
                        );
                    }
                }
                SeedsCmd::Add { seed, name } => {
                    let e = v.add(&seed_arg(&seed)?, name.as_deref())?;
                    println!("{}", e.id);
                }
                SeedsCmd::Remove { id } => {
                    if !v.remove(&id)? {
                        return Err("no seed with that id".into());
                    }
                }
            }
        }
        Cmd::Inactivity { cmd } => {
            let i = Inactivity::open_default()?;
            match cmd {
                InactivityCmd::Status => match i.status()? {
                    Status::Disabled => println!("disabled"),
                    Status::Armed { seconds_left } => {
                        println!("armed: {} days left", seconds_left / 86_400)
                    }
                    Status::Expired => println!("expired (will be wiped on the next enforce)"),
                },
                InactivityCmd::Enable { days } => {
                    i.configure(true, days)?;
                    println!(
                        "enabled: the local seed list is wiped after {days} days without activity"
                    );
                }
                InactivityCmd::Disable => {
                    i.configure(false, 90)?;
                    println!("disabled");
                }
                InactivityCmd::Enforce => println!(
                    "{}",
                    if i.enforce()? {
                        "wiped"
                    } else {
                        "nothing to do"
                    }
                ),
            }
        }
        Cmd::Version => {
            let v = slys_core::version();
            println!(
                "slys {} (seed format {}, commit {})",
                v.core, v.seed_format, v.commit
            );
        }
    }
    Ok(())
}

/// Tests and CI can lower the Argon2 cost with SLYS_FAST_KDF=1. Never set it for real data.
fn kdf_from_env() -> KdfParams {
    if std::env::var_os("SLYS_FAST_KDF").is_some() {
        eprintln!("warning: SLYS_FAST_KDF is set: key derivation is weakened. Testing only.");
        KdfParams::INSECURE_FAST
    } else {
        KdfParams::default()
    }
}

fn main() -> ExitCode {
    match run(Cli::parse()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("error: {e}");
            ExitCode::FAILURE
        }
    }
}
