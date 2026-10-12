#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Open Software Alliance contributors
# Self-test for check-rebrand.sh: runs it inside throwaway git repos.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
fails=0

run_case() { # name expected_exit file_path file_content
  local name="$1" want="$2" path="$3" content="$4" d rc
  d="$(mktemp -d)"
  mkdir -p "$d/Tools" "$d/$(dirname "$path")"
  cp "$here/check-rebrand.sh" "$d/Tools/"
  printf '%s\n' "$content" > "$d/$path"
  ( cd "$d" && git init -q && git add -A && ./Tools/check-rebrand.sh >/dev/null 2>&1 ); rc=$?
  rm -rf "$d"
  if [[ $rc -eq $want ]]; then echo "ok   $name"; else echo "FAIL $name (exit $rc, wanted $want)"; fails=$((fails+1)); fi
}

run_case "url + word Copyright on a code line fails" 1 Sources/A.swift 'let u = "https://github.com/vorssaint/x" // Copyright'
run_case "legacy token in non-allowlisted file fails" 1 Sources/A.swift 'let n = "Vorssaint Utils"'
run_case "legacy token in allowlisted file passes" 0 Tools/uninstall.sh 'LEGACY_APP="/Applications/Vorssaint Utils.app"'
run_case "extra vorssaint beside legacy token fails" 1 Tools/uninstall.sh 'x="Vorssaint Utils" vorssaint'
run_case "real copyright header passes" 0 Sources/A.swift '// Copyright (C) 2026 Vorssaint'
run_case "copyright with trailing text fails" 1 Sources/A.swift '// Copyright (C) 2026 Vorssaint see vorssaint.com'
run_case "team id fails" 1 Sources/A.swift 'let t = "3D485'"NHW29"'"'
run_case "clean repo passes" 0 Sources/A.swift 'let a = 1'
exit $((fails>0))
