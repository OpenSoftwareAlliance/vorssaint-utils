// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Open Software Alliance contributors

import Foundation

enum OSABuildConfigurationTests {
    static func run(_ suite: TestSuite) {
        suite.run("OSABuildConfiguration") {
            // Team id: exactly 10 uppercase letters/digits, trimmed.
            suite.expect(OSABuildConfiguration.teamID(in: nil) == nil, "no plist -> no team")
            suite.expect(OSABuildConfiguration.teamID(in: [:]) == nil, "missing key -> no team")
            suite.expect(OSABuildConfiguration.teamID(in: ["OSATeamID": ""]) == nil, "empty -> no team")
            suite.expect(OSABuildConfiguration.teamID(in: ["OSATeamID": "  ABCDE12345 "]) == "ABCDE12345", "trimmed team")
            suite.expect(OSABuildConfiguration.teamID(in: ["OSATeamID": "abcde12345"]) == nil, "lowercase rejected")
            suite.expect(OSABuildConfiguration.teamID(in: ["OSATeamID": "ABC"]) == nil, "short rejected")
            suite.expect(OSABuildConfiguration.teamID(in: ["OSATeamID": "ABCDE12345\"; rm"]) == nil, "injection rejected")

            // Share endpoint: https only, host required, whitespace = unset.
            suite.expect(OSABuildConfiguration.shareEndpoint(in: nil) == nil, "no plist -> no endpoint")
            suite.expect(OSABuildConfiguration.shareEndpoint(in: ["OSAShareEndpoint": "   "]) == nil, "blank -> none")
            suite.expect(OSABuildConfiguration.shareEndpoint(in: ["OSAShareEndpoint": "http://share.example"]) == nil, "http rejected")
            suite.expect(OSABuildConfiguration.shareEndpoint(in: ["OSAShareEndpoint": "notaurl"]) == nil, "garbage rejected")
            suite.expect(OSABuildConfiguration.shareEndpoint(in: ["OSAShareEndpoint": "https://"]) == nil, "no host rejected")
            suite.expect(OSABuildConfiguration.shareEndpoint(in: ["OSAShareEndpoint": " https://share.osa.better-web.org "])?.absoluteString
                         == "https://share.osa.better-web.org", "valid endpoint trimmed")

            for bad in ["https://user:pw@share.example", "https://share.example?x=1",
                        "https://share.example/#frag", "https://share.example/v1"] {
                suite.expect(OSABuildConfiguration.shareEndpoint(in: ["OSAShareEndpoint": bad]) == nil,
                             "build endpoint rejects userinfo/query/fragment/path: \(bad)")
            }

            let strings = Strings.enUS
            suite.expect(strings.updateActionButton(teamID: nil) == strings.networkDownload, "unsigned build shows Download")
            suite.expect(strings.updateActionButton(teamID: "ABCDE12345") == strings.updateInstallButton, "signed build shows install")

            // Repository: owner/name, else default.
            suite.expect(OSABuildConfiguration.repository(in: nil) == "OpenSoftwareAlliance/osa-desktop", "default repo")
            suite.expect(OSABuildConfiguration.repository(in: ["OSARepository": "me/fork"]) == "me/fork", "custom repo")
            suite.expect(OSABuildConfiguration.repository(in: ["OSARepository": "bad repo/x y"]) == "OpenSoftwareAlliance/osa-desktop", "invalid repo -> default")
            suite.expect(OSABuildConfiguration.releasesPageURL(in: nil).absoluteString
                         == "https://github.com/OpenSoftwareAlliance/osa-desktop/releases", "release page")
        }
    }
}
