#!/usr/bin/env bash
# Fails if the places that store the version disagree. CI runs it on every push; the release
# workflow also passes the tag (v1.2.3) to make sure the tag matches.
set -euo pipefail
cd "$(dirname "$0")/.."

cargo_ver=$(grep -m1 -E '^version = "' Cargo.toml | sed -E 's/version = "([^"]*)"/\1/')
pub_ver=$(grep -m1 -E '^version: ' app/pubspec.yaml | sed -E 's/version: ([^+ ]*).*/\1/')
meta_ver=$(grep -m1 -oE '<release version="[^"]*"' packaging/flatpak/io.github.gugeldot.Slys.metainfo.xml | sed -E 's/.*"([^"]*)"/\1/')

fail=0
[[ "$cargo_ver" == "$pub_ver" ]] || { echo "Cargo.toml ($cargo_ver) != app/pubspec.yaml ($pub_ver)"; fail=1; }
[[ "$cargo_ver" == "$meta_ver" ]] || { echo "Cargo.toml ($cargo_ver) != newest <release> in the metainfo ($meta_ver)"; fail=1; }
if [[ $# -ge 1 ]]; then
  tag="${1#v}"
  [[ "$cargo_ver" == "$tag" ]] || { echo "Cargo.toml ($cargo_ver) != tag ($1)"; fail=1; }
fi
[[ $fail -eq 0 ]] && echo "version OK: $cargo_ver"
exit $fail
