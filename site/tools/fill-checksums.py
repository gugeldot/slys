#!/usr/bin/env python3
"""Fill the SHA-256 placeholders in index.html from a release's SHA256SUMS file.

Usage:  python3 site/tools/fill-checksums.py SHA256SUMS

SHA256SUMS is the file the Release workflow publishes (lines of "<sha256>  <file name>").
Windows card <- Slys_Installer.exe, Linux card <- Slys.flatpak and Slys_Linux.zip.
"""
import pathlib
import re
import sys

WANTED = {
    "windows": "Slys_Installer.exe",
    "flatpak": "Slys.flatpak",
    "linux": "Slys_Linux.zip",
}

if len(sys.argv) != 2:
    sys.exit(__doc__)

sums = {}
for line in pathlib.Path(sys.argv[1]).read_text(encoding="utf8").splitlines():
    m = re.match(r"^([0-9a-fA-F]{64})\s+\*?(.+)$", line.strip())
    if m:
        sums[m.group(2).strip()] = m.group(1).lower()

index = pathlib.Path(__file__).resolve().parent.parent / "index.html"
html = index.read_text(encoding="utf8")
for key, name in WANTED.items():
    if name not in sums:
        sys.exit("%s is not listed in %s" % (name, sys.argv[1]))
    html, n = re.subn(r'(<code id="sha-%s">)[^<]*(</code>)' % key, r"\g<1>%s\g<2>" % sums[name], html)
    if n != 1:
        sys.exit("placeholder sha-%s not found in index.html" % key)
    print("%-8s %s  %s" % (key, sums[name], name))
index.write_text(html, encoding="utf8")
