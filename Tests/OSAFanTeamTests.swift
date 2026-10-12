// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Open Software Alliance contributors

import Foundation

enum OSAFanTeamTests {
    static func run(_ suite: TestSuite) {
        suite.run("OSAFanTeam") {
            // Requirement strings keep both the team clause and the identifier.
            let app = FanControlIdentifiers.codeRequirement(teamID: "ABCDE12345",
                                                            identifier: "org.better-web.osa.desktop")
            suite.expect(app == #"anchor apple generic and certificate leaf[subject.OU] = "ABCDE12345" and identifier "org.better-web.osa.desktop""#,
                         "app requirement carries the team and the bundle id: \(app ?? "nil")")
            let helper = FanControlIdentifiers.codeRequirement(teamID: "ABCDE12345",
                                                               identifier: "org.better-web.osa.desktop.fan-control")
            suite.expect(helper?.contains(#"leaf[subject.OU] = "ABCDE12345""#) == true
                         && helper?.contains(#"identifier "org.better-web.osa.desktop.fan-control""#) == true,
                         "helper requirement carries the team and the helper id")

            // Fail closed: no valid team means no requirement at all, never a weaker one.
            for bad in ["", "abcde12345", "ABCDE1234", "ABCDE123456", "ABCDE1234\"", "ABCDE 2345"] {
                suite.expect(FanControlIdentifiers.codeRequirement(teamID: bad, identifier: "x") == nil,
                             "invalid team '\(bad)' yields no requirement")
                suite.expect(!FanControlIdentifiers.isAvailable(teamID: bad),
                             "invalid team '\(bad)' makes fan control unavailable")
            }
            suite.expect(FanControlIdentifiers.isAvailable(teamID: "ABCDE12345"), "a valid team enables fan control")

            // The compiled-in identifiers follow the new bundle ids.
            suite.expect(FanControlIdentifiers.helperID == FanControlIdentifiers.appBundleID + ".fan-control",
                         "helper id derives from the app bundle id")
            suite.expect(FanControlIdentifiers.appBundleID.hasPrefix("org.better-web.osa.desktop"),
                         "app bundle id is the OSA Desktop id")
            suite.expect(FanControlIdentifiers.isAvailable == FanControlIdentifiers.isValidTeamID(OSABuildTeam.teamID),
                         "availability follows the build-time team")
        }
    }
}
