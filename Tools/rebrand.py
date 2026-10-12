#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Open Software Alliance contributors
"""Deterministic Vorssaint -> OSA Desktop rename (spec 001 R4). Idempotent."""
import argparse
import fnmatch
import os
import re
import subprocess
import sys

EXCLUDE = ["LICENSE", "CHANGELOG.md", "NOTICE", "TRADEMARKS.md", "README.md",
           "docs/specs/*", "Tools/rebrand.py", "Tools/test_rebrand.py",
           "Tools/check-rebrand.sh", ".git/*"]
PROSE_EXT = (".strings", ".plist", ".md", ".json", ".yml", ".yaml", ".txt", ".html")
CODE_EXT = (".swift", ".c", ".h", ".m", ".pl")
LOWER_WORD = re.compile(r"(?<![A-Za-z0-9_.\-/])vorssaint(?![A-Za-z0-9_\-])|(?<=\.)vorssaint(?![A-Za-z0-9_\-])")

URLS = [
    (re.compile(r"https?://(www\.)?vorssaint\.com[^\s\"')>]*"), "https://osa.better-web.org"),
    (re.compile(r"(github\.com|raw\.githubusercontent\.com)/vorssaint/vorssaint-utils"),
     r"\1/OpenSoftwareAlliance/osa-desktop"),
    (re.compile(r"hello@vorssaint\.com"), "https://github.com/OpenSoftwareAlliance/osa-desktop/issues"),
    (re.compile(r"com\.vorssaint\.utils"), "org.better-web.osa.desktop"),
    (re.compile(r"com\.vorssaint(?!\.utils)"), "org.better-web.osa"),
]
# Internal names stay for the internal phase: directory segments ("Sources/Vorssaint/",
# "build/Vorssaint", "Application Support/Vorssaint/"), dotted/hyphen-lowercase identifiers
# ("Vorssaint.Tests.X", "Vorssaint-update") and the legacy upstream name "Vorssaint Utils".
# "/Applications/Vorssaint.app" is a display path and is rewritten.
WORD = re.compile(r"(?<![A-Za-z0-9_])(?<!Sources/)(?<!build/)Vorssaint(?![A-Za-z0-9_/])(?!\.(?!app\b)[A-Za-z_])(?!-[a-z])(?! Utils)")
STRING_LITERAL = re.compile(r'"(?:[^"\\]|\\.)*"')


def excluded(path):
    p = path.replace(os.sep, "/").lstrip("./")
    return any(fnmatch.fnmatch(p, pat) for pat in EXCLUDE)


def _visible_line(path, line):
    for rx, rep in URLS:
        line = rx.sub(rep, line)
    if path.endswith(PROSE_EXT):
        return WORD.sub("OSA Desktop", line)
    if path.endswith(".swift"):
        return STRING_LITERAL.sub(lambda m: WORD.sub("OSA Desktop", m.group(0)), line)
    return line


def _internal_segment(seg, code):
    seg = seg.replace("VORSSAINT_", "OSA_DESKTOP_").replace("VORSSAINT", "OSA_DESKTOP")
    seg = seg.replace("Vorssaint", "OSADesktop")
    seg = seg.replace("vorssaint_", "osa_desktop_")
    seg = re.sub(r"vorssaint(?=[A-Z])", "osaDesktop", seg)
    if code:
        seg = LOWER_WORD.sub("osaDesktop", seg)
    return seg.replace("vorssaint", "osa-desktop")


def _internal_line(line, path=""):
    if not path.endswith(CODE_EXT):
        return _internal_segment(line, code=False)
    # Code outside string literals gets identifier forms; literals get path forms.
    out, last = [], 0
    for m in STRING_LITERAL.finditer(line):
        out.append(_internal_segment(line[last:m.start()], code=True))
        out.append(_internal_segment(m.group(0), code=False))
        last = m.end()
    out.append(_internal_segment(line[last:], code=True))
    return "".join(out)


def rewrite_text(path, text, phase):
    if excluded(path):
        return text
    out = []
    for line in text.splitlines(keepends=True):
        if "Copyright" in line or "©" in line:
            out.append(line)
        elif phase == "visible":
            out.append(_visible_line(path, line))
        else:
            out.append(_internal_line(line, path))
    return "".join(out)


def tracked_files(root):
    res = subprocess.run(["git", "-C", root, "ls-files", "-z"], capture_output=True, check=True)
    return [p for p in res.stdout.decode().split("\0") if p]


def rename_paths(root, phase):
    if phase != "internal":
        return []
    moves = []
    for path in sorted(tracked_files(root), key=len, reverse=True):
        if excluded(path):
            continue
        new = _internal_line(path)
        if new != path:
            moves.append((path, new))
    return moves


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", choices=["visible", "internal"], required=True)
    ap.add_argument("--root", default=".")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    changed = 0
    for path in tracked_files(a.root):
        full = os.path.join(a.root, path)
        if excluded(path) or not os.path.isfile(full):
            continue
        try:
            text = open(full, encoding="utf-8").read()
        except UnicodeDecodeError:
            continue
        new = rewrite_text(path, text, a.phase)
        if new != text:
            changed += 1
            if not a.dry_run:
                open(full, "w", encoding="utf-8").write(new)
    moves = rename_paths(a.root, a.phase)
    for old, new in moves:
        if not a.dry_run:
            os.makedirs(os.path.join(a.root, os.path.dirname(new)) or a.root, exist_ok=True)
            subprocess.run(["git", "-C", a.root, "mv", old, new], check=True)
    print(f"{a.phase}: {changed} files rewritten, {len(moves)} paths moved")
    return 0


if __name__ == "__main__":
    sys.exit(main())
