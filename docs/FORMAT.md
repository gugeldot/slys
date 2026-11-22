# SLYS file formats (seed v2 and fragments)

This document is the specification. It is public on purpose: the security of SLYS rests on the
password, never on the format being secret (Kerckhoffs's principle, see the last section).

All integers are big-endian. `||` means concatenation.

## What you need to rebuild a file

1. the **seed** (text),
2. the **password**,
3. the **fragment files**.

The key for every fragment is derived from the password *and* the salt stored in the seed, so the
password alone is not enough, and neither is the seed alone.

## Key derivation

```
master  = Argon2id(NFKC(password), salt, m, t, lanes, 32 bytes)
seedkey = HKDF-SHA256(master, info = "slys v2 seed")
fragkey = HKDF-SHA256(master, info = "slys v2 fragment" || seed_id || index_u32)
```

* The password is normalised with Unicode NFKC so the same text typed on different systems gives
  the same key.
* Default cost: `m = 65536 KiB (64 MiB)`, `t = 3`, `lanes = 1`. The parameters are stored in the
  seed, so they can be raised in the future without breaking existing seeds.
* When reading a seed the parameters are bounded (`m <= 1 GiB`, `t <= 32`, `lanes <= 16`) so a
  crafted seed cannot exhaust memory or time.
* One Argon2id run per operation (not per fragment).

## Seed text

```
SLYS2.<base64url, no padding, of BODY>.<CRC-32 as 8 lowercase hex digits>
```

* Whitespace anywhere in the pasted text is ignored (seeds get wrapped by editors and chats).
* The CRC-32 is computed over the ASCII of everything before the last `.` (prefix included). It
  exists **only** to catch typing and copy/paste mistakes before any expensive key derivation. It
  is not a security feature; integrity comes from the AEAD tag below.

### BODY

| Offset | Size | Field | Meaning | Secret? |
|---|---|---|---|---|
| 0 | 4 | magic | ASCII `SLYS` | no |
| 4 | 1 | version | `2` | no |
| 5 | 1 | kdf id | `1` = Argon2id | no |
| 6 | 4 | m | Argon2 memory, KiB | no |
| 10 | 4 | t | Argon2 passes | no |
| 14 | 1 | lanes | Argon2 parallelism | no |
| 15 | 16 | salt | random | no |
| 31 | 12 | nonce | random, AES-GCM | no |
| 43 | 4 | ct_len | length of what follows | no |
| 47 | ct_len | ciphertext | AES-256-GCM(seedkey, nonce, aad = bytes 0..43, PAYLOAD) incl. 16-byte tag | **yes** |

The header (bytes 0..43) is authenticated as associated data, so changing any parameter breaks
the tag.

### PAYLOAD (the only encrypted part)

| Size | Field |
|---|---|
| 16 | `seed_id`, random, binds fragments to this seed |
| 1 | mode: `0` Plain, `1` Light, `2` Full |
| 8 | original size |
| 32 | SHA-256 of the original file |
| 2 + n | original file name (UTF-8, length-prefixed) |
| 4 | fragment count (2 to 10000) |
| per fragment: 2 + n, 8, 32 | file name, size on disk, SHA-256 of the file on disk |

File names read from a seed must be plain names: no `/`, `\`, NUL, `.` or `..`. Anything else is
rejected, so a malicious seed cannot make SLYS read or write outside the chosen folders.

## Fragment files

Fragment names are random (`16 alphanumerics + .slys`) and reveal nothing.

* **Plain mode**: the file is a raw slice of the original. Nothing is encrypted.
* **Light mode**: only the first and last fragments are encrypted, the others are raw slices.
  This leaves most of the file readable. It exists for speed and for compatibility with 1.x's
  "Mid" level, and is not recommended.
* **Full mode** (default): every fragment is encrypted:

```
"SLYF" | 0x01 | nonce_prefix[7] | chunk*
```

Chunks are 64 KiB of plaintext (the last may be shorter) encrypted with AES-256-GCM using the
STREAM construction (BE32 counter + last-chunk flag), key = `fragkey`, associated data =
`seed_id || index_u32`. This detects modified, reordered, dropped and truncated chunks, and
fragments from another seed or in the wrong position.

Independently of the encryption, the seed stores the SHA-256 of every fragment file and of the
original, and SLYS checks both while rebuilding.

## Safety rules the implementation follows

* Nothing is deleted before the result is verified byte for byte.
* Output files are written under a temporary name and renamed only when complete.
* A failed decryption is an error. It never produces a corrupted output.
* Fragments are never deleted when rebuilding fails.

## SLYS 1.x seeds (read-only)

SLYS 1.0 to 1.5.x used: seed = `base64(salt16 || iv16 || AES-256-CBC(PKCS7, text))` with key
`PBKDF2-HMAC-SHA256(password, salt, 100000)`; fragments encrypted the same way with password
`password + "+2/"`. Text = `count|--|name|--|MODE=/#/=frag=/#/=...=/#/=|=-=|` with MODE `N`
(none), `P` (first and last) or `T` (all). Version 2 can rebuild these (there are test vectors made
by the real 1.5.1 in `crates/slys-core/tests/fixtures/v1`) but never writes them. Unlike 1.x, a
failed decryption is now an error instead of silently writing ciphertext and deleting the pieces.

## Kerckhoffs's principle

*The system must remain secure even if everything about it, except the key, is public.*

* **Satisfied:** the algorithms (Argon2id, HKDF-SHA256, AES-256-GCM), the formats and the constants
  are all public. The only secret is the password. Salts, nonces, cost parameters, names and the
  `SLYS`/`SLYF` markers are public by design. The fixed string that 1.x appended to passwords
  (`+2/`) never was a secret and gave no security; v2 has no such constant, only domain-separation
  labels in HKDF.
* **Not satisfied by design, and documented as such:** in **Plain** and **Light** modes the data
  is (partly) not encrypted, so what protects it is only that nobody knows the fragment order and
  names. That is obscurity, not cryptography. Use **Full** for real protection.
* **The seed** is encrypted and authenticated: knowing the format does not help without the
  password.
