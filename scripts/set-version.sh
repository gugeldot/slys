#!/usr/bin/env bash
# Sets the version everywhere it is stored. The single source of truth is the workspace version
# in Cargo.toml; the Rust core, the CLI, the bridge and the About screen read it from there.
#   scripts/set-version.sh 1.7.0 [build-number]
set -euo pipefail
cd "$(dirname "$0")/.."

ver="${1:?usage: $0 MAJOR.MINOR.PATCH [build-number]}"
build="${2:-1}"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "error: '$ver' is not MAJOR.MINOR.PATCH" >&2; exit 1; }

# first `version = "..."` line of the workspace manifest
sed -i -E '0,/^version = "[^"]*"/s//version = "'"$ver"'"/' Cargo.toml
sed -i -E "s/^version: .*/version: $ver+$build/" app/pubspec.yaml
cargo update --workspace --quiet 2>/dev/null || true

echo "version set to $ver (build $build)"
echo "remember: add a <release> entry for $ver in packaging/flatpak/io.github.gugeldot.Slys.metainfo.xml and CHANGELOG.md"
scripts/check-version.sh "v$ver"
