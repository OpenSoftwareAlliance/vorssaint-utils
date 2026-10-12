// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Open Software Alliance contributors

import Foundation

enum FeedbackEndpoint {
    /// nil when the build has no share endpoint configured: feedback is hidden.
    static func url(production: URL?) -> URL? {
        production?.appendingPathComponent("v1", isDirectory: true).appendingPathComponent("feedback")
    }

    static var isAvailable: Bool { url(production: OSABuildConfiguration.shareEndpoint()) != nil }
}
