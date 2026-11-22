#!/usr/bin/env bash
# Fragments a random 1 MB file and rebuilds it with the CLI, to see the core working.
# Uses a throwaway config directory and the FAST (insecure) key derivation: demo only.
set -euo pipefail
cd "$(dirname "$0")/.."

work=$(mktemp -d)
export SLYS_CONFIG_DIR="$work/config" SLYS_PASSWORD="demo-password" SLYS_FAST_KDF=1

head -c 1000000 /dev/urandom > "$work/sample.bin"
echo "original:"; sha256sum "$work/sample.bin"

seed=$(cargo run -q -p slys-cli -- frag "$work/sample.bin" -o "$work/frags" -n 8 --original keep)
echo "seed: ${seed:0:60}..."
ls "$work/frags"

cargo run -q -p slys-cli -- compose "$seed" -f "$work/frags" -o "$work/out" --delete-fragments keep
echo "rebuilt:"; sha256sum "$work/out/sample.bin"
echo "(files are in $work)"
