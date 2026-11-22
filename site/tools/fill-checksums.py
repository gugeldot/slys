#!/usr/bin/env python3
"""Fill the SHA-256 placeholders in index.html from the release files.

Usage:  python3 tools/fill-checksums.py Slys_Installer.exe Slys_Linux.zip
(first argument = Windows installer, second = Linux ZIP; use the exact files you upload to GitHub Releases)
"""
import hashlib, re, sys, pathlib

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()

if len(sys.argv) != 3:
    sys.exit(__doc__)
index = pathlib.Path(__file__).resolve().parent.parent / 'index.html'
html = index.read_text(encoding='utf8')
for key, file in (('windows', sys.argv[1]), ('linux', sys.argv[2])):
    digest = sha256(file)
    html, n = re.subn(r'(<code id="sha-%s">)[^<]*(</code>)' % key, r'\g<1>%s\g<2>' % digest, html)
    if n != 1:
        sys.exit('placeholder sha-%s not found' % key)
    print(key, digest)
index.write_text(html, encoding='utf8')
