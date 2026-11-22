<div align="center">
<img src="app/assets/images/invert_slys.png" alt="SLYS" width="360" />

**Fragment and encrypt your files. Rebuild them with a seed and a password.**

[Website](https://gugeldot.github.io/slys/) · [Download](https://github.com/gugeldot/slys/releases) · [Security](SECURITY.md) · [Format](docs/FORMAT.md)
</div>

## What it does

SLYS splits a file into pieces and encrypts every piece. To get the file back you need three
things: the **seed** (a short text), the **password**, and the **pieces**. Without all three the
data cannot be rebuilt.

* Every fragment is encrypted and authenticated (AES-256-GCM); the key comes from your password
  with Argon2id.
* Any change to a fragment is detected. Fragments from another seed, in the wrong order or
  truncated are rejected.
* The seed has a checksum, so a typo is reported immediately instead of failing later.
* Nothing is deleted until the rebuilt file has been verified byte for byte.
* SLYS itself never connects to the network (links in the app only open your browser when you click them).
* Seeds made by SLYS 1.x can still be used.

## Install

Get the files from the [Releases](https://github.com/gugeldot/slys/releases) page and verify them:

```
sha256sum -c SHA256SUMS
gh attestation verify Slys_Installer.exe --repo gugeldot/slys
```

| Platform | File |
|---|---|
| Windows 10+ | `Slys_Installer.exe` (or `Slys_Windows_Portable.zip`) |
| Linux | `Slys.flatpak` (`flatpak install --user Slys.flatpak`) or `Slys_Linux.zip` |

macOS is planned (see [docs/RELEASING.md](docs/RELEASING.md)).

## Use it from the terminal

```
slys frag report.pdf -o ./pieces -n 8        # prints the seed; asks for the password
slys compose "$SEED" -f ./pieces -o ./out    # rebuilds report.pdf
slys inspect "$SEED"                         # check a seed for typos, no password needed
```

Passwords are never accepted as arguments (they would show up in `ps` and in your shell history).

## Build from source

```
git clone https://github.com/gugeldot/slys && cd slys
cargo test --workspace            # the core and the CLI
cd app && flutter build linux     # or: flutter build windows
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) (setup, fast edit loop, tests) and
[docs/RELEASING.md](docs/RELEASING.md).

## Honest limits

SLYS is not audited and it is not magic: a weak password, a compromised computer or the
*Plain*/*Light* modes weaken it, and secure deletion on SSDs is best effort. Read
[SECURITY.md](SECURITY.md) before trusting it with something important.

## License

[GPL-3.0-or-later](LICENSE).
