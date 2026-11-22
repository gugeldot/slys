use std::process::Command;

fn main() {
    // Embed the short git commit so the About screen can show exactly what was built.
    // Release builds can override it with SLYS_GIT_COMMIT (e.g. when building from a tarball).
    let commit = std::env::var("SLYS_GIT_COMMIT")
        .ok()
        .filter(|s| !s.is_empty())
        .or_else(|| {
            Command::new("git")
                .args(["rev-parse", "--short=9", "HEAD"])
                .output()
                .ok()
                .filter(|o| o.status.success())
                .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        })
        .unwrap_or_else(|| "unknown".to_string());
    println!("cargo:rustc-env=SLYS_GIT_COMMIT={commit}");
    println!("cargo:rerun-if-env-changed=SLYS_GIT_COMMIT");
    println!("cargo:rerun-if-changed=../../.git/HEAD");
}
