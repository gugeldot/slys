#!/usr/bin/env bash
# Writes SHA256SUMS for every release asset in a directory.
#   scripts/make-checksums.sh dist
set -euo pipefail
dir="${1:?usage: $0 DIR}"
cd "$dir"
rm -f SHA256SUMS
# shellcheck disable=SC2035
sha256sum $(ls -1 | grep -v '^SHA256SUMS$' | sort) > SHA256SUMS
cat SHA256SUMS
