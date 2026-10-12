# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Open Software Alliance contributors
import unittest
from rebrand import rewrite_text


class VisiblePhase(unittest.TestCase):
    def v(self, path, text):
        return rewrite_text(path, text, "visible")

    def test_string_literal_name(self):
        self.assertEqual(self.v("a.swift", 'let t = "Hide Vorssaint windows"'),
                         'let t = "Hide OSA Desktop windows"')

    def test_code_untouched_in_visible(self):
        self.assertEqual(self.v("a.swift", "let x = VorssaintMenuBarItem()"),
                         "let x = VorssaintMenuBarItem()")

    def test_bundle_id_and_urls(self):
        self.assertEqual(self.v("a.swift", '"com.vorssaint.utils.dev"'), '"org.better-web.osa.desktop.dev"')
        self.assertEqual(self.v("a.md", "see https://vorssaint.com/x"), "see https://osa.better-web.org")
        self.assertEqual(
            self.v("a.swift", '"https://raw.githubusercontent.com/vorssaint/vorssaint-utils/main/Resources/agent-prices.json"'),
            '"https://raw.githubusercontent.com/OpenSoftwareAlliance/osa-desktop/main/Resources/agent-prices.json"')

    def test_bare_vorssaint_prefix_ids(self):
        self.assertEqual(self.v("a.swift", 'hasPrefix("com.vorssaint")'), 'hasPrefix("org.better-web.osa")')
        self.assertEqual(self.v("a.swift", '"com.vorssaint.tests.delayed.plist"'),
                         '"org.better-web.osa.tests.delayed.plist"')
        self.assertEqual(self.v("a.swift", '"com.vorssaint.utils.dev"'), '"org.better-web.osa.desktop.dev"')

    def test_path_segments_left_for_internal_phase(self):
        self.assertEqual(self.v("a.swift", '"Sources/Vorssaint/App/X.swift"'), '"Sources/Vorssaint/App/X.swift"')
        self.assertEqual(self.v("a.md", "run `./build/Vorssaint --selftest`"), "run `./build/Vorssaint --selftest`")

    def test_identifier_suffixes_left_for_internal_phase(self):
        self.assertEqual(self.v("a.swift", '"Vorssaint.Tests.X"'), '"Vorssaint.Tests.X"')
        self.assertEqual(self.v("a.swift", '"Vorssaint-update.dmg"'), '"Vorssaint-update.dmg"')
        self.assertEqual(self.v("a.swift", '"Vorssaint.app"'), '"OSA Desktop.app"')
        self.assertEqual(self.v("a.md", "Open Vorssaint. Then wait; Vorssaint-Symbol"), "Open OSA Desktop. Then wait; OSA Desktop-Symbol")

    def test_display_path_rewritten_but_not_segments(self):
        self.assertEqual(self.v("a.swift", '"/Applications/Vorssaint.app"'), '"/Applications/OSA Desktop.app"')
        self.assertEqual(self.v("a.swift", '"Sources/Vorssaint/App"'), '"Sources/Vorssaint/App"')
        self.assertEqual(self.v("a.swift", '"/Applications/Vorssaint Utils.app"'), '"/Applications/Vorssaint Utils.app"')

    def test_copyright_sign_preserved(self):
        line = 'static let copyright = "© 2026 Vorssaint"'
        self.assertEqual(self.v("a.swift", line), line)

    def test_copyright_preserved(self):
        line = "// Copyright (C) 2026 Vorssaint"
        self.assertEqual(self.v("a.swift", line), line)
        self.assertEqual(rewrite_text("a.swift", line, "internal"), line)

    def test_excluded_file(self):
        self.assertEqual(self.v("LICENSE", "Vorssaint"), "Vorssaint")
        self.assertEqual(rewrite_text("docs/specs/x.md", "Vorssaint", "internal"), "Vorssaint")


class InternalPhase(unittest.TestCase):
    def i(self, path, text):
        return rewrite_text(path, text, "internal")

    def test_identifiers(self):
        self.assertEqual(self.i("a.swift", "VorssaintMenuBarItem.1"), "OSADesktopMenuBarItem.1")
        self.assertEqual(self.i("a.swift", "DefaultsKey.hideVorssaintWindows"), "DefaultsKey.hideOSADesktopWindows")
        self.assertEqual(self.i("a.swift", "#if VORSSAINT_DEVELOPMENT"), "#if OSA_DESKTOP_DEVELOPMENT")
        self.assertEqual(self.i("a.swift", "func vorssaintSource()"), "func osaDesktopSource()")

    def test_lowercase_code_symbols(self):
        self.assertEqual(self.i("a.swift", "    case vorssaint, coffee, eye"), "    case osaDesktop, coffee, eye")
        self.assertEqual(self.i("a.swift", "style != .vorssaint)"), "style != .osaDesktop)")
        self.assertEqual(self.i("a.swift", "vorssaint_read_vm_statistics64(&raw)"), "osa_desktop_read_vm_statistics64(&raw)")
        self.assertEqual(self.i("x.pl", "vorssaint_now_playing_get()"), "osa_desktop_now_playing_get()")

    def test_lowercase_paths(self):
        self.assertEqual(self.i("a.swift", '".vorssaint"'), '".osa-desktop"')
        self.assertEqual(self.i("a.swift", '"vorssaint-update-\\(pid)"'), '"osa-desktop-update-\\(pid)"')
        self.assertEqual(self.i("build.sh", "Sources/Vorssaint/App"), "Sources/OSADesktop/App")

    def test_string_literal_word_left_for_visible(self):
        # A standalone word inside a literal was already handled by the visible phase.
        self.assertEqual(self.i("a.swift", 'let t = "Hide OSA Desktop windows"'),
                         'let t = "Hide OSA Desktop windows"')

    def test_legacy_upstream_names_protected(self):
        self.assertEqual(self.i("a.swift", 'let legacy = "Vorssaint Utils"'), 'let legacy = "Vorssaint Utils"')
        self.assertEqual(self.i("a.sh", 'pkill -x VorssaintUtils'), 'pkill -x VorssaintUtils')
        self.assertEqual(self.i("a.sh", 'LEGACY_APP="/Applications/Vorssaint Utils.app"; X=Vorssaint'),
                         'LEGACY_APP="/Applications/Vorssaint Utils.app"; X=OSADesktop')

    def test_legacy_sudoers_rules_protected(self):
        line = '"/etc/sudoers.d/vorssaint-clamshell", "/etc/sudoers.d/vorssaint-utils-clamshell"'
        self.assertEqual(self.i("a.swift", line), line)
        self.assertEqual(self.i("uninstall.sh", "RULES=(/etc/sudoers.d/vorssaint-clamshell)"),
                         "RULES=(/etc/sudoers.d/vorssaint-clamshell)")


class Idempotence(unittest.TestCase):
    def test_second_run_noop(self):
        src = '// Copyright (C) 2026 Vorssaint\nlet a = VorssaintX("Vorssaint", "com.vorssaint.utils")\n'
        once = rewrite_text("a.swift", rewrite_text("a.swift", src, "visible"), "internal")
        twice = rewrite_text("a.swift", rewrite_text("a.swift", once, "visible"), "internal")
        self.assertEqual(once, twice)
        self.assertIn("Copyright (C) 2026 Vorssaint", once)


if __name__ == "__main__":
    unittest.main()
