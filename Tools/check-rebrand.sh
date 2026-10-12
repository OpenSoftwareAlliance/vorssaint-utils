#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Open Software Alliance contributors
# Spec 001 AC2/AC3/AC8: fail if Vorssaint identity leaks outside the allowlist.
# Runs against the git repository that contains this script (Tools/..).
set -euo pipefail
cd "$(dirname "$0")/.."

# Whole files that may mention Vorssaint freely: license, history, notice, README credits,
# specs, legacy assets pending removal (docs/assets/readme/) and the rebrand tooling.
allow_files='^(LICENSE|CHANGELOG\.md|NOTICE|README\.md|docs/specs/|docs/assets/readme/|Tools/(rebrand\.py|test_rebrand\.py|check-rebrand\.sh|test_check_rebrand\.sh))'

# Real copyright header lines only: a comment marker, then the notice and nothing else.
copyright_header='^[[:space:]]*(//|#|\*)[[:space:]]*Copyright \(C\) [0-9]{4}(-[0-9]{4})? Vorssaint[[:space:]]*$'

# Legacy names that must keep working (migration, uninstall, old signing identity, old sudoers rules),
# allowed only in the listed files: "file|token|token...". Longer tokens first.
legacy_rules=(
  'Sources/OSADesktop/Core/BundleMigration.swift|Vorssaint Utils'
  'Sources/OSADesktop/Services/ShellSupport.swift|vorssaint-utils-clamshell|vorssaint-clamshell'
  'Tools/uninstall.sh|Vorssaint Utils|VorssaintUtils|vorssaint-utils-clamshell|vorssaint-clamshell'
  'build.sh|Vorssaint Utils|VorssaintUtils'
  'Tests/DeveloperInstallIsolationTests.sh|Vorssaint Utils|VorssaintUtils'
)

# Exact notice lines (after trimming), per file: "file|exact line".
exact_lines=(
  'Resources/Info.plist|<string>© 2026 Vorssaint and Open Software Alliance contributors</string>'
  'Sources/OSADesktop/Core/AppInfo.swift|static let copyright = "© 2026 Vorssaint and Open Software Alliance contributors"'
  'TRADEMARKS.md|OSA Desktop is a fork of Vorssaint and is not affiliated with or endorsed by'
  'TRADEMARKS.md|the Vorssaint project. See [NOTICE](NOTICE).'
)

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; echo "${s%"${s##*[![:space:]]}"}"; }

# $1 = "path:line:text"; returns 0 when the hit is an allowed exception.
allowed() {
  local hit="$1" file text rule IFS tok rest
  file="${hit%%:*}"; rest="${hit#*:}"; text="${rest#*:}"
  [[ "$text" =~ $copyright_header ]] && return 0
  local t; t="$(trim "$text")"
  for rule in "${exact_lines[@]}"; do
    [[ "${rule%%|*}" == "$file" && "${rule#*|}" == "$t" ]] && return 0
  done
  for rule in "${legacy_rules[@]}"; do
    [[ "${rule%%|*}" == "$file" ]] || continue
    IFS='|' read -r -a toks <<<"${rule#*|}"
    local stripped="$text"
    for tok in "${toks[@]}"; do stripped="${stripped//"$tok"/}"; done
    shopt -s nocasematch
    [[ "$stripped" == *vorssaint* ]] && { shopt -u nocasematch; return 1; }
    shopt -u nocasematch
    return 0
  done
  return 1
}

leaks=""
while IFS= read -r hit; do
  [[ -z "$hit" ]] && continue
  [[ "$hit" =~ $allow_files ]] && continue
  allowed "$hit" || leaks+="$hit"$'\n'
done < <(git grep -n -I -i vorssaint || true)

hosts=$(git grep -n -i 'vorssaint\.com' | grep -Ev "$allow_files" || true)
# Split so this script does not itself contain the upstream team id.
team_id="3D485""NHW29"
team=$(git grep -n "$team_id" | grep -Ev '^docs/specs/' || true)

status=0
[[ -n "$leaks" ]] && { echo "Vorssaint references outside allowlist:"; printf '%s' "$leaks"; status=1; }
[[ -n "$hosts" ]] && { echo "vorssaint.com references:"; echo "$hosts"; status=1; }
[[ -n "$team"  ]] && { echo "Vorssaint team id found:"; echo "$team"; status=1; }
[[ $status == 0 ]] && echo "rebrand check OK"
exit $status
