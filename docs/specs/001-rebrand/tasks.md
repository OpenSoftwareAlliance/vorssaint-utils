# 001 Rebrand to OSA Desktop: tasks

Read [plan.md](plan.md) (Global Constraints, Review Focus) and [spec.md](spec.md) first. Paths are relative to the repo root. Until Task 7 runs, Swift sources live in `Sources/Vorssaint/`; afterwards in `Sources/OSADesktop/`.

Every commit is GPG-signed (repo default `commit.gpgsign=true`) and ends with the trailer `Co-Authored-By: <agent> <noreply@…>`.

---

### Task 0: Baseline

**Files:**
- Create: `docs/specs/001-rebrand/baseline.md`

- [ ] **Step 1: Build and test the unmodified fork**

Run:
```bash
./build.sh 2>&1 | tail -20
./build.sh --test 2>&1 | tee /tmp/osa-baseline-tests.txt | tail -40
```
Expected: a built `build/stage/Vorssaint.app` (or the error), and a final `TESTS OK (N checks)` or `TESTS FAILED (k of N)`.

- [ ] **Step 2: Record the result**

Write `docs/specs/001-rebrand/baseline.md` with: date, commit (`git rev-parse HEAD`), `swift --version`, macOS version (`sw_vers`), build outcome, the test summary line, and the list of failing checks (copied from the `TESTS FAILED` block), if any. Failures here are pre-existing and are not caused by the rebrand.

- [ ] **Step 3: Commit**

```bash
git add docs/specs/001-rebrand/baseline.md
git commit -m "docs(specs): record 001 baseline build and tests"
```

---

### Task 1: `OSABuildConfiguration`

**Files:**
- Create: `Sources/Vorssaint/Core/OSABuildConfiguration.swift`
- Create: `Tests/OSABuildConfigurationTests.swift`
- Modify: `build.sh` (TEST_SOURCES list near line 248; Info.plist block near line 660)
- Modify: `Tests/MetricsTests.swift` (suite table near line 62)

**Interfaces:**
- Produces:
  - `OSABuildConfiguration.teamID(in info: [String: Any]?) -> String?`
  - `OSABuildConfiguration.shareEndpoint(in info: [String: Any]?) -> URL?`
  - `OSABuildConfiguration.repository(in info: [String: Any]?) -> String`
  - `OSABuildConfiguration.releasesPageURL(in info: [String: Any]?) -> URL`
  - `OSABuildConfiguration.isLinkSharingAvailable: Bool`
  - Info.plist keys `OSATeamID`, `OSAShareEndpoint`, `OSARepository`; env vars `OSA_TEAM_ID`, `OSA_SHARE_ENDPOINT`, `OSA_REPOSITORY`.

- [ ] **Step 1: Write the failing test** — `Tests/OSABuildConfigurationTests.swift`

```swift
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

            // Repository: owner/name, else default.
            suite.expect(OSABuildConfiguration.repository(in: nil) == "OpenSoftwareAlliance/osa-desktop", "default repo")
            suite.expect(OSABuildConfiguration.repository(in: ["OSARepository": "me/fork"]) == "me/fork", "custom repo")
            suite.expect(OSABuildConfiguration.repository(in: ["OSARepository": "bad repo/x y"]) == "OpenSoftwareAlliance/osa-desktop", "invalid repo -> default")
            suite.expect(OSABuildConfiguration.releasesPageURL(in: nil).absoluteString
                         == "https://github.com/OpenSoftwareAlliance/osa-desktop/releases/latest", "release page")
        }
    }
}
```

Register it in `Tests/MetricsTests.swift`, in the suite table next to `("updates", { … })`:

```swift
            ("osa-config", { OSABuildConfigurationTests.run(suite) }),
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./build.sh --test-suite=osa-config`
Expected: compile error `cannot find 'OSABuildConfiguration' in scope`.

- [ ] **Step 3: Implement** — `Sources/Vorssaint/Core/OSABuildConfiguration.swift`

```swift
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
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              let url = components.url
        else { return nil }
        return url
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
        URL(string: "https://github.com/\(repository(in: info))/releases/latest")!
    }

    static var isLinkSharingAvailable: Bool { shareEndpoint() != nil }
}
```

Add `Sources/Vorssaint/Core/OSABuildConfiguration.swift` as the first entry of the `TEST_SOURCES=(` array in `build.sh`. The app build compiles every file under `Sources/Vorssaint`, so no change is needed there (verify with `grep -n 'find Sources' build.sh`; if the app uses an explicit list, add the file there too).

In `build.sh`, right after `cp Resources/Info.plist "$STAGE/Contents/Info.plist"`, add:

```bash
# OSA build-time configuration (see Sources/…/Core/OSABuildConfiguration.swift).
/usr/libexec/PlistBuddy -c "Add :OSATeamID string ${OSA_TEAM_ID:-}" "$STAGE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :OSAShareEndpoint string ${OSA_SHARE_ENDPOINT:-}" "$STAGE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :OSARepository string ${OSA_REPOSITORY:-OpenSoftwareAlliance/osa-desktop}" "$STAGE/Contents/Info.plist"
```

- [ ] **Step 4: Run tests**

Run: `./build.sh --test-suite=osa-config` → `OSABuildConfiguration: OK`. Then `./build.sh` → builds; `/usr/libexec/PlistBuddy -c "Print :OSARepository" build/stage/*.app/Contents/Info.plist` → `OpenSoftwareAlliance/osa-desktop`.

- [ ] **Step 5: Commit**

```bash
git add Sources/Vorssaint/Core/OSABuildConfiguration.swift Tests/OSABuildConfigurationTests.swift Tests/MetricsTests.swift build.sh
git commit -m "feat: add OSA build-time configuration (team id, share endpoint, repository)"
```

---

### Task 2: Gate link sharing and feedback (R3)

**Files:**
- Modify: `Sources/Vorssaint/Services/QuickTools/ScreenshotSharingSupport.swift:84-93`
- Modify: `Sources/Vorssaint/Services/Recorder/RecordingSharingSupport.swift:48-60`
- Modify: `Sources/Vorssaint/Services/Feedback/FeedbackService.swift:61,92`
- Modify: `Sources/Vorssaint/Services/QuickTools/ScreenshotShareService.swift:50-55,86`
- Modify: `Sources/Vorssaint/Services/Recorder/RecordingShareService.swift:50-55,92`
- Modify (hide controls): `Services/QuickTools/ScreenshotService.swift` (162-175, 651), `Services/QuickTools/ScreenshotQuickPreviewController.swift` (266), `Services/QuickTools/ScreenshotEditorController.swift`, `Services/Recorder/RecorderEditorController.swift`, `UI/Screenshot/ScreenshotEditorView.swift`, `UI/Recorder/RecorderEditorView.swift`, `UI/Settings/ScreenshotSettings.swift`, `UI/Settings/ScreenRecorderSettings.swift`, `UI/Settings/GeneralSettings.swift:153`, `UI/MenuPanel/MenuPanelView.swift:530`, `App/AppDelegate.swift:1748`
- Create: `Tests/OSALinkSharingGateTests.swift`
- Modify: `Tests/MetricsTests.swift`

**Interfaces:**
- Consumes: `OSABuildConfiguration.shareEndpoint(in:)`, `.isLinkSharingAvailable`
- Produces:
  - `ScreenshotSharingSupport.endpoint(bundleIdentifier:developerOverride:production:) -> URL?`
  - `RecordingSharingSupport.endpoint(bundleIdentifier:developerOverride:production:) -> URL?`
  - `FeedbackService.endpoint(production:) -> URL?` (static), `FeedbackService.isAvailable: Bool`
  - `ScreenshotShareService.endpoint: URL?`, `RecordingShareService.endpoint: URL?`

- [ ] **Step 1: Write the failing test** — `Tests/OSALinkSharingGateTests.swift`

```swift
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
            // Developer override still works with no production endpoint (Review Focus 1).
            suite.expect(ScreenshotSharingSupport.endpoint(bundleIdentifier: dev,
                                                           developerOverride: "https://localhost.test",
                                                           production: nil)?.host == "localhost.test",
                         "screenshot: developer override without production endpoint")
            // Override is ignored for production bundle ids.
            suite.expect(ScreenshotSharingSupport.endpoint(bundleIdentifier: "org.better-web.osa.desktop",
                                                           developerOverride: "https://evil.test",
                                                           production: nil) == nil,
                         "screenshot: override ignored outside developer build")
            // Feedback.
            suite.expect(FeedbackService.endpoint(production: nil) == nil, "feedback: unavailable when unconfigured")
            suite.expect(FeedbackService.endpoint(production: prod)?.absoluteString
                         == "https://share.osa.better-web.org/v1/feedback", "feedback: path appended")
            // No Vorssaint host anywhere in the defaults.
            suite.expect(OSABuildConfiguration.shareEndpoint(in: [:]) == nil, "no built-in default endpoint")
        }
    }
}
```

Register in `Tests/MetricsTests.swift`: `("osa-sharing-gate", { OSALinkSharingGateTests.run(suite) }),`. Add `Sources/Vorssaint/Services/Feedback/FeedbackService.swift` to `TEST_SOURCES` in `build.sh` if it is not there (`grep -n FeedbackService build.sh`); if it pulls UI dependencies, move `endpoint(production:)` into a new `Services/Feedback/FeedbackEndpoint.swift` (`enum FeedbackEndpoint { static func url(production:) -> URL? }`) and test that instead, keeping `FeedbackService.endpoint(production:)` as a one-line forwarder.

- [ ] **Step 2: Run test to verify it fails**

Run: `./build.sh --test-suite=osa-sharing-gate`
Expected: compile errors (extra argument `production`, no member `endpoint(production:)`).

- [ ] **Step 3: Implement the endpoints**

`ScreenshotSharingSupport.swift` — replace `productionEndpoint` and `endpoint(...)`:

```swift
    static let developerBundleIdentifier = "com.vorssaint.utils.dev"
    static let maximumUploadBytes = 25 * 1_024 * 1_024

    /// nil when this build has no OSA share endpoint and is not a developer
    /// build with an override: link sharing is then hidden (spec 001 R3).
    static func endpoint(bundleIdentifier: String?, developerOverride: String?,
                         production: URL? = OSABuildConfiguration.shareEndpoint()) -> URL? {
        if bundleIdentifier == developerBundleIdentifier,
           let developerOverride,
           let candidate = sanitizedEndpoint(developerOverride) {
            return candidate
        }
        return production
    }
```

`RecordingSharingSupport.swift` — same shape, delegating sanitizing to `ScreenshotSharingSupport.sanitizedEndpoint` as today:

```swift
    static func endpoint(bundleIdentifier: String?, developerOverride: String?,
                         production: URL? = OSABuildConfiguration.shareEndpoint()) -> URL? {
        if bundleIdentifier == developerBundleIdentifier,
           let developerOverride,
           let candidate = ScreenshotSharingSupport.sanitizedEndpoint(developerOverride) {
            return candidate
        }
        return production
    }
```

`FeedbackService.swift` — replace the hardcoded `endpoint` property:

```swift
    static func endpoint(production: URL? = OSABuildConfiguration.shareEndpoint()) -> URL? {
        production?.appendingPathComponent("v1", isDirectory: true).appendingPathComponent("feedback")
    }
    static var isAvailable: Bool { endpoint() != nil }
```

and at the request site (line ~92): `guard let endpoint = Self.endpoint() else { throw FeedbackError.unavailable }` before `var request = URLRequest(url: endpoint)`.

`ScreenshotShareService.swift` / `RecordingShareService.swift`: change `var endpoint: URL {` to `var endpoint: URL? {` (body unchanged) and add `var isAvailable: Bool { endpoint != nil }`. At the upload site replace `let serviceEndpoint = endpoint` with:

```swift
        guard let serviceEndpoint = endpoint else { throw ScreenshotShareError.unavailable }
```
(`RecordingShareError.unavailable` in the recording service). Existing records keep their stored `record.endpoint` (line 172), so deleting previously shared links still targets the server that hosts them.

- [ ] **Step 4: Hide the controls**

In each file listed under "Modify (hide controls)", wrap every control that starts a link share, shows a "copy link"/"upload" action or opens feedback in a condition on availability, and make shortcut handlers return early:

```swift
if ScreenshotShareService.shared.isAvailable {
    // existing share-link button / menu item / settings section
}
```

```swift
if FeedbackService.isAvailable {
    // existing "Send feedback" button
}
```

In `ScreenshotService.swift` (lines 162 and 173) treat the upload shortcut as disabled when `!ScreenshotShareService.shared.isAvailable`. In `AppDelegate.openFeedbackWindow(kind:)` add `guard FeedbackService.isAvailable else { return }` as the first line. Use the services' real singleton names as found in each file (`grep -n "static let shared" Services/QuickTools/ScreenshotShareService.swift Services/Recorder/RecordingShareService.swift`).

Check that nothing was missed:

```bash
grep -rn "shareLink\|copySharedLink\|openFeedbackWindow\|uploadShortcut" Sources | grep -v isAvailable
```
Every remaining hit must be either inside a gated block, a definition, or a call path that only runs after a gated control.

- [ ] **Step 5: Run tests and build**

Run: `./build.sh --test-suite=osa-sharing-gate` → OK; `./build.sh --test` → same result as baseline plus the new suites; `git grep -n "screenshots.vorssaint.com" Sources` → no output.

- [ ] **Step 6: Commit**

```bash
git add -A Sources Tests build.sh
git commit -m "feat: make link sharing and feedback endpoint configurable, hidden when unset"
```

---

### Task 3: Safe updates (R7)

**Files:**
- Modify: `Sources/Vorssaint/Services/Update/UpdateInstallerSupport.swift:26,66,123`
- Modify: `Sources/Vorssaint/Services/Update/UpdateService.swift:30,208-349`
- Create: `Tests/OSAUpdateTeamTests.swift`
- Modify: `Tests/MetricsTests.swift`; any existing test calling `installerScript()` (`grep -rn "installerScript()" Tests`)

**Interfaces:**
- Consumes: `OSABuildConfiguration.teamID(in:)`, `.repository(in:)`, `.releasesPageURL(in:)`
- Produces:
  - `UpdateInstallerSupport.installerScript(teamID: String, bundleID: String) -> String`
  - `UpdateInstallerSupport.verificationRequirement(teamID: String, bundleID: String?) -> String`
  - `UpdateInstallerSupport.installAction(teamID: String?) -> UpdateInstallAction` where `enum UpdateInstallAction: Equatable { case install(teamID: String), openReleasePage }`

- [ ] **Step 1: Write the failing test** — `Tests/OSAUpdateTeamTests.swift`

```swift
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
```

Register: `("osa-updates", { OSAUpdateTeamTests.run(suite) }),`.

- [ ] **Step 2: Run test to verify it fails**

Run: `./build.sh --test-suite=osa-updates` → compile errors (unknown members).

- [ ] **Step 3: Implement**

In `UpdateInstallerSupport.swift` add:

```swift
enum UpdateInstallAction: Equatable {
    case install(teamID: String)
    case openReleasePage
}

    static func installAction(teamID: String?) -> UpdateInstallAction {
        guard let teamID else { return .openReleasePage }
        return .install(teamID: teamID)
    }

    /// Team id is validated by OSABuildConfiguration (10 × [A-Z0-9]), so it is
    /// safe to embed; the bundle id comes from Bundle.main.
    static func verificationRequirement(teamID: String, bundleID: String?) -> String {
        let anchor = #"anchor apple generic and certificate leaf[subject.OU] = "\#(teamID)""#
        guard let bundleID else { return anchor }
        return #"identifier "\#(bundleID)" and \#(anchor)"#
    }
```

Change `static func installerScript() -> String` to `static func installerScript(teamID: String, bundleID: String) -> String`, and in its body replace the two hardcoded lines:

```swift
        DMG_VERIFY_REQ=\(shellSingleQuoted(verificationRequirement(teamID: teamID, bundleID: nil)))
```
```swift
                    VERIFY_REQ=\(shellSingleQuoted(verificationRequirement(teamID: teamID, bundleID: bundleID)))
```
(If the script is a raw string literal `#"""…"""#`, use `\#(…)` interpolation.) Update existing callers/tests of `installerScript()` to pass `teamID: "ABCDE12345", bundleID: "org.better-web.osa.desktop"`.

In `UpdateService.swift`:
- line 30: `private let repository = OSABuildConfiguration.repository()`
- first lines of `downloadAndInstall()`, after the developer-build guard:

```swift
        switch UpdateInstallerSupport.installAction(teamID: OSABuildConfiguration.teamID()) {
        case .openReleasePage:
            NSWorkspace.shared.open(OSABuildConfiguration.releasesPageURL())
            return
        case .install:
            break
        }
```
- at line ~349: `try UpdateInstallerSupport.installerScript(teamID: teamID, bundleID: Bundle.main.bundleIdentifier ?? "")` where `teamID` is unwrapped with `guard let teamID = OSABuildConfiguration.teamID() else { return }` at the top of that function.

Checking for updates and posting the notification are unchanged (Review Focus 5): only the install step differs.

- [ ] **Step 4: Run tests**

Run: `./build.sh --test-suite=osa-updates` → OK; `./build.sh --test-suite=updates` → same as baseline; `git grep -n 3D485NHW29 -- Sources` → nothing.

- [ ] **Step 5: Commit**

```bash
git add -A Sources Tests
git commit -m "feat: parameterize update signing team; open release page when unsigned"
```

---

### Task 4: Identity in build, plists and CI (R1, R5)

**Files:**
- Modify: `build.sh:26-41` (APP_NAME, EXECUTABLE, APP_BUNDLE_ID, compile flag), lines 668-694 (PlistBuddy keys)
- Modify: `Resources/Info.plist`
- Rename+modify: `Resources/com.vorssaint.utils.fan-control.plist` → `Resources/org.better-web.osa.desktop.fan-control.plist`; `Resources/Vorssaint.entitlements` → `Resources/OSADesktop.entitlements`
- Modify: `.github/workflows/ci.yml`, `.github/workflows/release.yml`

- [ ] **Step 1: build.sh identity**

```bash
if (( DEV )); then
    APP_NAME="OSA Desktop (Developer)"
    EXECUTABLE="OSADesktopDeveloper"
    APP_BUNDLE_ID="org.better-web.osa.desktop.dev"
    BUILD_VARIANT_FLAGS=(-D OSA_DESKTOP_DEVELOPMENT)
    …
else
    APP_NAME="OSA Desktop"
    EXECUTABLE="OSADesktop"
    APP_BUNDLE_ID="org.better-web.osa.desktop"
    …
fi
```
Update every other reference in `build.sh` to the renamed plist/entitlements files and the helper id (`grep -n -i vorssaint build.sh`): `Delete :MachServices:com.vorssaint.utils.fan-control` → `Delete :MachServices:org.better-web.osa.desktop.fan-control`; `VorssaintBuildCommit` / `VorssaintFanControlHelperVersion` plist keys → `OSABuildCommit` / `OSAFanControlHelperVersion` and their readers in `Sources` (`git grep -n "VorssaintBuildCommit\|VorssaintFanControlHelperVersion" Sources`). The `VORSSAINT_DEVELOPMENT` `#if` sites in Sources are renamed in Task 7; until then add `-D VORSSAINT_DEVELOPMENT` alongside the new flag in the DEV branch so behavior does not change between commits, and remove it in Task 7.

- [ ] **Step 2: Info.plist and entitlements**

`git mv` the two resource files. In `Resources/Info.plist` set `CFBundleIdentifier` `org.better-web.osa.desktop`, `CFBundleName`/`CFBundleDisplayName` `OSA Desktop`, `CFBundleExecutable` `OSADesktop`, and replace "Vorssaint" with "OSA Desktop" in every `NS*UsageDescription`. In the helper plist set `Label`, `BundleProgram` and the `MachServices` key to the new helper id.

- [ ] **Step 3: CI unsigned**

`ci.yml`: replace any `Vorssaint.app` path with `OSA Desktop.app` (quote the path). `release.yml`: wrap the signing, notarization and `codesign --verify` steps with `if: ${{ secrets.OSA_TEAM_ID != '' }}` (or an env check at job level), replace the hardcoded `REQUIREMENT=` lines with requirements built from `${{ secrets.OSA_TEAM_ID }}` and the new bundle id, pass `OSA_TEAM_ID` to `./build.sh`, and change the release text to state the DMG is unsigned when no team is set ("Unsigned build: right-click → Open on first launch").

- [ ] **Step 4: Verify**

Run: `./build.sh && ./build.sh --dev`; then
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "build/stage/OSA Desktop.app/Contents/Info.plist"
```
Expected: `org.better-web.osa.desktop`. Run `./build.sh --test` → baseline result. Run `git grep -n 3D485NHW29` → nothing.

- [ ] **Step 5: Commit**

```bash
git add -A build.sh Resources .github
git commit -m "chore: OSA Desktop app identity, bundle ids and unsigned CI"
```

---

### Task 5: `Tools/rebrand.py` with tests (R4)

**Files:**
- Create: `Tools/rebrand.py`
- Create: `Tools/test_rebrand.py`

**Interfaces:**
- Produces: `python3 Tools/rebrand.py --phase visible|internal [--root .] [--dry-run]`; functions `rewrite_text(path: str, text: str, phase: str) -> str`, `rename_paths(root, phase) -> list[tuple[str, str]]`.

Rules (applied in this order; lines containing `Copyright` are never changed; files in `EXCLUDE` are never changed):

| Phase | Pattern | Replacement |
|---|---|---|
| visible | `https://vorssaint.com…` / `https://www.vorssaint.com…` | `https://osa.better-web.org` |
| visible | `github.com/vorssaint/vorssaint-utils` and `raw.githubusercontent.com/vorssaint/vorssaint-utils` | same host + `OpenSoftwareAlliance/osa-desktop` |
| visible | `hello@vorssaint.com` | `https://github.com/OpenSoftwareAlliance/osa-desktop/issues` |
| visible | `com.vorssaint.utils` | `org.better-web.osa.desktop` |
| visible | standalone word `Vorssaint` inside a Swift string literal, or anywhere in `.strings`, `.plist`, `.md`, `.json`, `.yml` | `OSA Desktop` |
| internal | `VORSSAINT_` / `VORSSAINT` | `OSA_DESKTOP_` / `OSA_DESKTOP` |
| internal | `Vorssaint` in Swift code (outside string literals), in shell, Python | `OSADesktop` |
| internal | `vorssaint_` (C/Perl symbols such as `vorssaint_read_vm_statistics64`, `vorssaint_now_playing_get`) | `osa_desktop_` |
| internal | `vorssaint` immediately followed by an uppercase letter (camelCase start) | `osaDesktop` |
| internal | standalone `vorssaint` in Swift/C/Objective-C/Perl **code** outside string literals (enum case `case vorssaint`, member `.vorssaint`) | `osaDesktop` |
| internal | remaining `vorssaint` (inside string literals, shell, Python, paths, prefixes like `".vorssaint"`, `vorssaint-update-`) | `osa-desktop` |
| internal | path segments containing `Vorssaint`/`vorssaint` (e.g. `Sources/Vorssaint`) | same rules → `git mv` |

`EXCLUDE`: `LICENSE`, `CHANGELOG.md`, `NOTICE`, `TRADEMARKS.md`, `README.md`, `docs/specs/**`, `Tools/rebrand.py`, `Tools/test_rebrand.py`, `Tools/check-rebrand.sh`, `.git/**`, binary files (non-UTF-8).

- [ ] **Step 1: Write the failing tests** — `Tools/test_rebrand.py`

```python
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


class Idempotence(unittest.TestCase):
    def test_second_run_noop(self):
        src = '// Copyright (C) 2026 Vorssaint\nlet a = VorssaintX("Vorssaint", "com.vorssaint.utils")\n'
        once = rewrite_text("a.swift", rewrite_text("a.swift", src, "visible"), "internal")
        twice = rewrite_text("a.swift", rewrite_text("a.swift", once, "visible"), "internal")
        self.assertEqual(once, twice)
        self.assertIn("Copyright (C) 2026 Vorssaint", once)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd Tools && python3 -m unittest test_rebrand -v` → `ModuleNotFoundError: No module named 'rebrand'`.

- [ ] **Step 3: Implement** — `Tools/rebrand.py`

```python
#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Open Software Alliance contributors
"""Deterministic Vorssaint -> OSA Desktop rename (spec 001 R4). Idempotent."""
import argparse
import fnmatch
import os
import re
import subprocess
import sys

EXCLUDE = ["LICENSE", "CHANGELOG.md", "NOTICE", "TRADEMARKS.md", "README.md",
           "docs/specs/*", "Tools/rebrand.py", "Tools/test_rebrand.py",
           "Tools/check-rebrand.sh", ".git/*"]
PROSE_EXT = (".strings", ".plist", ".md", ".json", ".yml", ".yaml", ".txt", ".html")
CODE_EXT = (".swift", ".c", ".h", ".m", ".pl")
LOWER_WORD = re.compile(r"(?<![A-Za-z0-9_.\-/])vorssaint(?![A-Za-z0-9_\-])|(?<=\.)vorssaint(?![A-Za-z0-9_\-])")

URLS = [
    (re.compile(r"https?://(www\.)?vorssaint\.com[^\s\"')>]*"), "https://osa.better-web.org"),
    (re.compile(r"(github\.com|raw\.githubusercontent\.com)/vorssaint/vorssaint-utils"),
     r"\1/OpenSoftwareAlliance/osa-desktop"),
    (re.compile(r"hello@vorssaint\.com"), "https://github.com/OpenSoftwareAlliance/osa-desktop/issues"),
    (re.compile(r"com\.vorssaint\.utils"), "org.better-web.osa.desktop"),
]
WORD = re.compile(r"(?<![A-Za-z0-9_])Vorssaint(?![A-Za-z0-9_])")
STRING_LITERAL = re.compile(r'"(?:[^"\\]|\\.)*"')


def excluded(path):
    p = path.replace(os.sep, "/").lstrip("./")
    return any(fnmatch.fnmatch(p, pat) for pat in EXCLUDE)


def _visible_line(path, line):
    for rx, rep in URLS:
        line = rx.sub(rep, line)
    if path.endswith(PROSE_EXT):
        return WORD.sub("OSA Desktop", line)
    if path.endswith(".swift"):
        return STRING_LITERAL.sub(lambda m: WORD.sub("OSA Desktop", m.group(0)), line)
    return line


def _internal_segment(seg, code):
    seg = seg.replace("VORSSAINT_", "OSA_DESKTOP_").replace("VORSSAINT", "OSA_DESKTOP")
    seg = seg.replace("Vorssaint", "OSADesktop")
    seg = seg.replace("vorssaint_", "osa_desktop_")
    seg = re.sub(r"vorssaint(?=[A-Z])", "osaDesktop", seg)
    if code:
        seg = LOWER_WORD.sub("osaDesktop", seg)
    return seg.replace("vorssaint", "osa-desktop")


def _internal_line(line, path=""):
    if not path.endswith(CODE_EXT):
        return _internal_segment(line, code=False)
    # Code outside string literals gets identifier forms; literals get path forms.
    out, last = [], 0
    for m in STRING_LITERAL.finditer(line):
        out.append(_internal_segment(line[last:m.start()], code=True))
        out.append(_internal_segment(m.group(0), code=False))
        last = m.end()
    out.append(_internal_segment(line[last:], code=True))
    return "".join(out)


def rewrite_text(path, text, phase):
    if excluded(path):
        return text
    out = []
    for line in text.splitlines(keepends=True):
        if "Copyright" in line:
            out.append(line)
        elif phase == "visible":
            out.append(_visible_line(path, line))
        else:
            out.append(_internal_line(line, path))
    return "".join(out)


def tracked_files(root):
    res = subprocess.run(["git", "-C", root, "ls-files", "-z"], capture_output=True, check=True)
    return [p for p in res.stdout.decode().split("\0") if p]


def rename_paths(root, phase):
    if phase != "internal":
        return []
    moves = []
    for path in sorted(tracked_files(root), key=len, reverse=True):
        if excluded(path):
            continue
        new = _internal_line(path)
        if new != path:
            moves.append((path, new))
    return moves


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", choices=["visible", "internal"], required=True)
    ap.add_argument("--root", default=".")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    changed = 0
    for path in tracked_files(a.root):
        full = os.path.join(a.root, path)
        if excluded(path) or not os.path.isfile(full):
            continue
        try:
            text = open(full, encoding="utf-8").read()
        except UnicodeDecodeError:
            continue
        new = rewrite_text(path, text, a.phase)
        if new != text:
            changed += 1
            if not a.dry_run:
                open(full, "w", encoding="utf-8").write(new)
    moves = rename_paths(a.root, a.phase)
    for old, new in moves:
        if not a.dry_run:
            os.makedirs(os.path.join(a.root, os.path.dirname(new)) or a.root, exist_ok=True)
            subprocess.run(["git", "-C", a.root, "mv", old, new], check=True)
    print(f"{a.phase}: {changed} files rewritten, {len(moves)} paths moved")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run tests**

Run: `cd Tools && python3 -m unittest test_rebrand -v` → all OK. Then `python3 Tools/rebrand.py --phase visible --dry-run` and `--phase internal --dry-run` print counts without modifying (`git status --short` empty).

- [ ] **Step 5: Commit**

```bash
git add Tools/rebrand.py Tools/test_rebrand.py
git commit -m "chore: add deterministic rebrand script with tests"
```

---

### Task 6: Run phase `visible` (R1)

- [ ] **Step 1: Run**

```bash
python3 Tools/rebrand.py --phase visible
git diff --stat | tail -3
```

- [ ] **Step 2: Review the diff**

`git diff -U0 | grep '^[-+]' | grep -v '^[-+][-+]' | head -200`: every change is a URL, bundle id or a user-visible "Vorssaint" → "OSA Desktop" in text. Remove Discord / Buy Me a Coffee links and the `discord-symbol.svg` reference by hand where they appear in UI or plist (`git grep -n -i "discord\|buymeacoffee" Sources Resources`), replacing the action with the Issues URL or deleting the menu item.

- [ ] **Step 3: Verify**

`./build.sh && ./build.sh --test` → baseline result. `python3 Tools/rebrand.py --phase visible` again → `0 files rewritten`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: rebrand user-visible text, URLs and bundle ids to OSA Desktop"
```

---

### Task 7: Run phase `internal` (R4)

- [ ] **Step 1: Run**

```bash
python3 Tools/rebrand.py --phase internal
git status --short | head
```
Expected: `Sources/Vorssaint` moved to `Sources/OSADesktop`; `build.sh`, `Package.swift`, `Tests/generate_sources.py`, `Tests/*.swift` updated. Remove the temporary `-D VORSSAINT_DEVELOPMENT` flag added in Task 4 if the script did not already turn it into a duplicate `OSA_DESKTOP_DEVELOPMENT` (dedupe by hand).

- [ ] **Step 2: Verify**

```bash
./build.sh && ./build.sh --dev && ./build.sh --test
python3 Tools/rebrand.py --phase internal   # expect: 0 files rewritten, 0 paths moved  (AC5)
cd Tools && python3 -m unittest test_rebrand && cd ..
```
Test result must match the baseline (suite names renamed by the script are the same suites).

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: rename internal Vorssaint identifiers and paths to OSADesktop"
```

---

### Task 8: Provisional icon and wordmark (Codex)

**Files:**
- Replace: `Resources/Brand/AppIcon-Default.png` (1024×1024 macOS squircle icon)
- Replace: `Resources/Brand/logo.png` (wordmark/glyph, transparent background; `Tools/MakeIcon.swift` derives the menu bar template glyph and `BrandMark.png` from it)
- Replace: `Resources/Brand/AppIcon.icon/` (Icon Composer bundle; regenerate from the new PNG or, if not reproducible without Icon Composer, make `MakeIcon.swift` use only `AppIcon-Default.png` and delete the bundle after listing it for approval)

- [ ] **Step 1: Generate with Codex**

```bash
mkdir -p /tmp/osa-icon && cd /tmp/osa-icon
codex exec "Create two PNG files in the current directory. 1) app-icon.png, 1024x1024, a macOS Big Sur style squircle app icon for 'OSA Desktop' (Open Software Alliance): simple bold geometric mark combining a notch/island shape with an open circle, deep blue to teal gradient, no text, no Apple trademarks. 2) logo.png, 1024x1024, transparent background, the same mark only, solid single color white-on-transparent, suitable to derive a monochrome menu bar template icon. Save both files and print their paths."
```
Check: `sips -g pixelWidth -g pixelHeight -g hasAlpha app-icon.png logo.png` → 1024×1024; `logo.png` hasAlpha yes. Open both and look at them; regenerate if text or third-party marks appear.

- [ ] **Step 2: Install and build**

```bash
cp /tmp/osa-icon/app-icon.png Resources/Brand/AppIcon-Default.png
cp /tmp/osa-icon/logo.png Resources/Brand/logo.png
./build.sh --dev
```
Expected: `build/AppIcon.icns`, `build/MenuBarIcon.png`, `build/BrandMark.png` regenerated; open the app and confirm the Dock icon and menu bar glyph are the new mark.

- [ ] **Step 3: Commit**

```bash
git add Resources/Brand
git commit -m "feat: provisional OSA Desktop icon and wordmark (generated with Codex)"
```

---

### Task 9: Docs, allowlist check, verification (R6, AC2, AC3, AC6, AC7)

**Files:**
- Create: `Tools/check-rebrand.sh`, `NOTICE`
- Modify: `README.md` (generated), `TRADEMARKS.md`, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `docs/PRIVACY.md`, `docs/PERMISSIONS.md`, `docs/TROUBLESHOOTING.md`, `.github/workflows/ci.yml`

- [ ] **Step 1: Allowlist check** — `Tools/check-rebrand.sh`

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Open Software Alliance contributors
# Spec 001 AC2/AC3/AC8: fail if Vorssaint identity leaks outside the allowlist.
set -euo pipefail
cd "$(dirname "$0")/.."
allow='^(LICENSE|CHANGELOG\.md|NOTICE|README\.md|docs/specs/|Tools/(rebrand\.py|test_rebrand\.py|check-rebrand\.sh))'
leaks=$(git grep -n -i vorssaint | grep -Ev "$allow" | grep -v 'Copyright' || true)
hosts=$(git grep -n -i 'vorssaint\.com' | grep -Ev "$allow" || true)
team=$(git grep -n '3D485NHW29' || true)
status=0
[[ -n "$leaks" ]] && { echo "Vorssaint references outside allowlist:"; echo "$leaks"; status=1; }
[[ -n "$hosts" ]] && { echo "vorssaint.com references:"; echo "$hosts"; status=1; }
[[ -n "$team"  ]] && { echo "Vorssaint team id found:"; echo "$team"; status=1; }
[[ $status == 0 ]] && echo "rebrand check OK"
exit $status
```
Note: `README.md` is allowed only for its credits section; Step 3 makes the README generated so the only mention is the credit. Add a CI step to `ci.yml`: `- run: ./Tools/check-rebrand.sh`.

Run: `chmod +x Tools/check-rebrand.sh && ./Tools/check-rebrand.sh`. Fix every reported line (docs are next).

- [ ] **Step 2: NOTICE and TRADEMARKS**

`NOTICE`:
```
OSA Desktop
Copyright (C) 2026 Open Software Alliance contributors

OSA Desktop is a fork of Vorssaint (https://github.com/vorssaint/vorssaint-utils),
Copyright (C) Vorssaint and contributors, licensed under GPL-3.0-or-later.
OSA Desktop is not affiliated with or endorsed by the Vorssaint project.
```
`TRADEMARKS.md`: same structure as the original, with "OSA Desktop" and "Open Software Alliance" as the protected names, bundle identity `org.better-web.osa.desktop`, and the same rule that forks must rebrand.

- [ ] **Step 3: README**

Add an `osa-desktop` row to the org manifest used by `.osa/readme.py` in the workspace (`~/Dev/4-projetos/g-open-software-alliance/.osa/repos.tsv`, plus `DETAILS["osa-desktop"]` and issue links) and generate `README.md` with it. Features: Dynamic Island (music, calendar, timers, downloads, shelf), volume mixer and audio routing, system monitor and fan control, window management and app switcher, clipboard history and snippets, screen capture and recording. Stack: Swift 6 / AppKit + SwiftUI, macOS 14+ Apple Silicon. Credits: "OSA Desktop is based on Vorssaint".

- [ ] **Step 4: Other docs**

Replace product name and channels in `CONTRIBUTING.md`, `SECURITY.md` (report via GitHub Security Advisories of `OpenSoftwareAlliance/osa-desktop`), `SUPPORT.md`, `docs/PRIVACY.md` (state that link sharing and feedback are off unless an OSA share endpoint is configured at build time), `docs/PERMISSIONS.md`, `docs/TROUBLESHOOTING.md`.

- [ ] **Step 5: Branded README assets**

`docs/assets/readme/` holds Vorssaint logos and screenshots no longer referenced. List exact files with sizes (`git ls-files -z docs/assets/readme | xargs -0 du -h`), confirm none is referenced (`git grep -n "docs/assets/readme" -- ':!docs/specs'`), and **ask the repo owner to approve the exact list** before `git rm`.

- [ ] **Step 6: Full verification**

```bash
./Tools/check-rebrand.sh                      # AC2, AC3, AC8
python3 Tools/rebrand.py --phase visible && python3 Tools/rebrand.py --phase internal   # AC5: both report 0
./build.sh --test                             # AC1: same as baseline + new suites OK
./build.sh --dev && open "build/stage/OSA Desktop (Developer).app"
```
AC6: take a screenshot showing the menu bar item, the settings window title "OSA Desktop (Developer)" and the About panel; confirm `osascript -e 'id of app "OSA Desktop (Developer)"'` prints `org.better-web.osa.desktop.dev`. In the report, list which features were opened by hand and which are covered only by build/tests.

- [ ] **Step 7: Commit, push, PR**

```bash
git add -A
git commit -m "docs: OSA Desktop README, NOTICE, trademarks and support channels"
git push
gh pr create -R OpenSoftwareAlliance/vorssaint-utils --base main --head spec/001-rebrand \
  --title "Rebrand Vorssaint to OSA Desktop (spec 001)" --body-file <(printf 'Implements docs/specs/001-rebrand. Closes #21.\n')
```
AC7: CI green on the PR. After the owner merges: `gh repo rename osa-desktop -R OpenSoftwareAlliance/vorssaint-utils --yes`, update the local remote URL and the workspace manifest.
