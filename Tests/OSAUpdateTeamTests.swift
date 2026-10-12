// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Open Software Alliance contributors

import Foundation

enum OSAUpdateTeamTests {
    static func run(_ suite: TestSuite) {
        suite.run("OSAUpdateTeam") {
            suite.expect(UpdateInstallerSupport.installAction(teamID: nil) == .openReleasePage,
                         "no team id -> open release page, never auto-install")
            suite.expect(UpdateInstallerSupport.installAction(teamID: "ABCDE12345") == .install(teamID: "ABCDE12345"),
                         "team id -> install")

            let appReq = UpdateInstallerSupport.verificationRequirement(teamID: "ABCDE12345",
                                                                        bundleID: "org.better-web.osa.desktop")
            suite.expect(appReq == #"identifier "org.better-web.osa.desktop" and anchor apple generic and certificate leaf[subject.OU] = "ABCDE12345""#,
                         "app requirement uses configured team and new bundle id: \(appReq)")
            let dmgReq = UpdateInstallerSupport.verificationRequirement(teamID: "ABCDE12345", bundleID: nil)
            suite.expect(dmgReq == #"anchor apple generic and certificate leaf[subject.OU] = "ABCDE12345""#,
                         "dmg requirement uses configured team: \(dmgReq)")

            let script = UpdateInstallerSupport.installerScript(teamID: "ABCDE12345", bundleID: "org.better-web.osa.desktop")
            suite.expect(script.contains("ABCDE12345"), "script embeds team id")
            suite.expect(!script.contains("3D485NHW29"), "script has no Vorssaint team id")
            suite.expect(!script.contains("com.vorssaint.utils"), "script has no Vorssaint bundle id")
        }
    }
}
