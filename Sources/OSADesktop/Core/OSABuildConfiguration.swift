// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Open Software Alliance contributors

import Foundation

/// Build-time values that `build.sh` writes into Info.plist from environment
/// variables (`OSA_TEAM_ID`, `OSA_SHARE_ENDPOINT`, `OSA_REPOSITORY`).
/// Unset or invalid values mean "feature not configured".
enum OSABuildConfiguration {
    static let teamIDKey = "OSATeamID"
    static let shareEndpointKey = "OSAShareEndpoint"
    static let repositoryKey = "OSARepository"
    static let defaultRepository = "OpenSoftwareAlliance/osa-desktop"

    static func teamID(in info: [String: Any]? = Bundle.main.infoDictionary) -> String? {
        guard let raw = info?[teamIDKey] as? String else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count == 10,
              value.unicodeScalars.allSatisfy({ ("A"..."Z").contains($0) || ("0"..."9").contains($0) })
        else { return nil }
        return value
    }

    static func shareEndpoint(in info: [String: Any]? = Bundle.main.infoDictionary) -> URL? {
        guard let raw = info?[shareEndpointKey] as? String else { return nil }
        return sanitizedEndpoint(raw)
    }

    /// The single endpoint validator, shared by the build-time value and the
    /// developer override: https, a host, no userinfo, query, fragment or path.
    static func sanitizedEndpoint(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil,
              components.password == nil,
              components.query == nil,
              components.fragment == nil,
              components.path.isEmpty || components.path == "/"
        else { return nil }
        components.scheme = "https"
        components.path = ""
        return components.url
    }

    static func repository(in info: [String: Any]? = Bundle.main.infoDictionary) -> String {
        guard let raw = (info?[repositoryKey] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        else { return defaultRepository }
        let parts = raw.split(separator: "/", omittingEmptySubsequences: false)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        guard parts.count == 2,
              parts.allSatisfy({ !$0.isEmpty && $0.unicodeScalars.allSatisfy(allowed.contains) })
        else { return defaultRepository }
        return raw
    }

    static func releasesPageURL(in info: [String: Any]? = Bundle.main.infoDictionary) -> URL {
        URL(string: "https://github.com/\(repository(in: info))/releases")!
    }

    static var isLinkSharingAvailable: Bool { shareEndpoint() != nil }
}
