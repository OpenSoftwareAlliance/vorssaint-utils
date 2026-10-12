// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Open Software Alliance contributors

import Foundation

enum OSALinkSharingGateTests {
    static func run(_ suite: TestSuite) {
        suite.run("OSALinkSharingGate") {
            let dev = ScreenshotSharingSupport.developerBundleIdentifier
            let prod = URL(string: "https://share.osa.better-web.org")!

            // Production build, nothing configured -> unavailable.
            suite.expect(ScreenshotSharingSupport.endpoint(bundleIdentifier: "org.better-web.osa.desktop",
                                                           developerOverride: nil, production: nil) == nil,
                         "screenshot: no endpoint when unconfigured")
            suite.expect(RecordingSharingSupport.endpoint(bundleIdentifier: "org.better-web.osa.desktop",
                                                          developerOverride: nil, production: nil) == nil,
                         "recording: no endpoint when unconfigured")
            // Production build, configured -> that endpoint.
            suite.expect(ScreenshotSharingSupport.endpoint(bundleIdentifier: "org.better-web.osa.desktop",
                                                           developerOverride: nil, production: prod) == prod,
                         "screenshot: configured endpoint")
            suite.expect(RecordingSharingSupport.endpoint(bundleIdentifier: "org.better-web.osa.desktop",
                                                          developerOverride: nil, production: prod) == prod,
                         "recording: configured endpoint")
            // Developer override still works with no production endpoint.
            suite.expect(ScreenshotSharingSupport.endpoint(bundleIdentifier: dev,
                                                           developerOverride: "https://localhost.test",
                                                           production: nil)?.host == "localhost.test",
                         "screenshot: developer override without production endpoint")
            suite.expect(RecordingSharingSupport.endpoint(bundleIdentifier: RecordingSharingSupport.developerBundleIdentifier,
                                                          developerOverride: "https://localhost.test",
                                                          production: nil)?.host == "localhost.test",
                         "recording: developer override without production endpoint")
            // Override is ignored for production bundle ids.
            suite.expect(ScreenshotSharingSupport.endpoint(bundleIdentifier: "org.better-web.osa.desktop",
                                                           developerOverride: "https://evil.test",
                                                           production: nil) == nil,
                         "screenshot: override ignored outside developer build")
            // Feedback.
            suite.expect(FeedbackEndpoint.url(production: nil) == nil, "feedback: unavailable when unconfigured")
            suite.expect(FeedbackEndpoint.url(production: prod)?.absoluteString
                         == "https://share.osa.better-web.org/v1/feedback", "feedback: path appended")
            // Central shortcuts page lists the upload shortcut only with sharing.
            suite.expect(!GlobalShortcutRole.availableRoles(isAvailable: { _ in true },
                                                            linkSharingAvailable: false)
                            .contains(.screenshotUpload),
                         "shortcuts: upload role excluded when link sharing is unavailable")
            suite.expect(GlobalShortcutRole.availableRoles(isAvailable: { _ in true },
                                                           linkSharingAvailable: true)
                            .contains(.screenshotUpload),
                         "shortcuts: upload role included when link sharing is available")
            // No OSADesktop host anywhere in the defaults.
            suite.expect(OSABuildConfiguration.shareEndpoint(in: [:]) == nil, "no built-in default endpoint")
        }
    }
}
