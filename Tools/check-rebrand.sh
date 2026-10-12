#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Open Software Alliance contributors
# Spec 001 AC2/AC3/AC8: fail if Vorssaint identity leaks outside the allowlist.
set -euo pipefail
cd "$(dirname "$0")/.."

# Files that may mention Vorssaint freely: license, history, notice, credits and the rebrand tooling.
# docs/assets/readme/ holds legacy assets pending removal.
allow_files='^(LICENSE|CHANGELOG\.md|NOTICE|TRADEMARKS\.md|README\.md|docs/specs/|docs/assets/readme/|Tools/(rebrand\.py|test_rebrand\.py|check-rebrand\.sh))'
# Lines that may mention it anywhere: copyright notices and legacy tokens kept on purpose
# (migration, uninstall, cleanup of old sudoers rules, legacy signing identity).
allow_lines='Copyright|©|Vorssaint Utils|VorssaintUtils|vorssaint-clamshell|vorssaint-utils-clamshell'

leaks=$(git grep -n -i vorssaint | grep -Ev "$allow_files" | grep -Ev "$allow_lines" || true)
hosts=$(git grep -n -i 'vorssaint\.com' | grep -Ev "$allow_files" || true)
team=$(git grep -n '3D485NHW29' | grep -Ev '^(docs/specs/|Tools/check-rebrand\.sh)' || true)

status=0
[[ -n "$leaks" ]] && { echo "Vorssaint references outside allowlist:"; echo "$leaks"; status=1; }
[[ -n "$hosts" ]] && { echo "vorssaint.com references:"; echo "$hosts"; status=1; }
[[ -n "$team"  ]] && { echo "Vorssaint team id found:"; echo "$team"; status=1; }
[[ $status == 0 ]] && echo "rebrand check OK"
exit $status
