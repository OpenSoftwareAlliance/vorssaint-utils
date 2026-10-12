# 001 Rebrand to OSA Desktop: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Tasks live in [tasks.md](tasks.md) and use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Vorssaint fork into OSA Desktop (identity, infrastructure, internal names, icon, docs) without changing any feature behavior.

**Architecture:** One new source of truth, `OSABuildConfiguration`, reads build-time values from `Info.plist` (`OSATeamID`, `OSAShareEndpoint`, `OSARepository`) that `build.sh` writes from environment variables. Link sharing, feedback and the in-app installer consult it. Everything else is renamed by `Tools/rebrand.py`, a deterministic, idempotent script run in two phases (`visible`, then `internal`), each producing its own commit. `Tools/check-rebrand.sh` enforces the allowlist from AC2/AC3.

**Tech Stack:** Swift 6 (plain `swiftc` via `build.sh`, no SPM dependencies), the repo's own test harness (`Tests/TestSuite.swift`, `./build.sh --test`), Python 3 for tooling (stdlib `unittest`), bash, GitHub Actions, Codex CLI (`codex exec`) for the provisional logo.

**Spec:** [spec.md](spec.md)

## Global Constraints

- App name `OSA Desktop`; developer variant `OSA Desktop (Developer)`.
- Executables `OSADesktop` / `OSADesktopDeveloper`.
- Bundle ids `org.better-web.osa.desktop` / `org.better-web.osa.desktop.dev`; helper `<bundle id>.fan-control`.
- Swift sources dir `Sources/OSADesktop`; compile flag `OSA_DESKTOP_DEVELOPMENT`.
- Repository `OpenSoftwareAlliance/osa-desktop` (GitHub redirects the old name until the rename lands).
- Website `https://osa.better-web.org`; support = GitHub Issues of `OpenSoftwareAlliance/osa-desktop`.
- `OSAShareEndpoint` empty by default; must be `https` to be accepted.
- `OSA_TEAM_ID` unset by default → unsigned builds, no auto-install of updates.
- No request to `*.vorssaint.com`; no read from `vorssaint/*` repos; the string `3D485NHW29` appears nowhere.
- Copyright notice lines (`Copyright (C) … Vorssaint`) are never modified.
- No new SPM dependency; no feature added or removed; no behavior change other than R3 and R7.
- Every commit GPG-signed by the repo owner's key; never `--no-gpg-sign`.
- Report must separate what was reproduced by running the app from what only build/tests cover (`docs/AI-CONTRIBUTIONS.md`).

## Review Focus

1. **Developer endpoint override with an empty production endpoint:** a developer build with `screenshotSharingDeveloperEndpoint` set must still share to that override, while a production build with no `OSAShareEndpoint` hides sharing. Test in Task 2.
2. **Non-https or malformed `OSAShareEndpoint`** (e.g. `http://x`, `   `, `notaurl`) must count as "not configured", never crash or send data. Test in Task 1.
3. **Rebrand script touching copyright lines or `LICENSE`:** must leave them byte-identical. Test in Task 5.
4. **Rebrand script on mixed identifiers** (`hideVorssaintWindows`, `VorssaintMenuBarItem.1`, `.vorssaint`, `vorssaint-update-`, `VORSSAINT_DEVELOPMENT`, `"Hide Vorssaint windows"`): each maps to the documented form, and a second run is a no-op. Test in Task 5.
5. **Update check with no team id** must still report a newer version (check + notification) and only the install step changes to "open release page". Test in Task 3.

## File structure

| File | Responsibility | Task |
|---|---|---|
| `docs/specs/001-rebrand/baseline.md` (create) | Build/test result on the unmodified fork | 0 |
| `Sources/Vorssaint/Core/OSABuildConfiguration.swift` (create) | Read and validate `OSATeamID`, `OSAShareEndpoint`, `OSARepository` from a plist dictionary | 1 |
| `Tests/OSABuildConfigurationTests.swift` (create) | Suite `osa-config` | 1 |
| `build.sh` (modify) | Write the three keys; identity variables; register new test sources | 1, 4 |
| `Services/QuickTools/ScreenshotSharingSupport.swift`, `Services/Recorder/RecordingSharingSupport.swift`, `Services/Feedback/FeedbackService.swift` (modify) | Optional endpoint from `OSABuildConfiguration` | 2 |
| Share/feedback call sites (modify): `ScreenshotShareService.swift`, `RecordingShareService.swift`, `ScreenshotService.swift`, `ScreenshotQuickPreviewController.swift`, `ScreenshotEditorController.swift`, `RecorderEditorController.swift`, `UI/Screenshot/ScreenshotEditorView.swift`, `UI/Recorder/RecorderEditorView.swift`, `UI/Settings/ScreenshotSettings.swift`, `UI/Settings/ScreenRecorderSettings.swift`, `UI/Settings/GeneralSettings.swift`, `UI/MenuPanel/MenuPanelView.swift`, `App/AppDelegate.swift` | Hide link sharing / feedback when unavailable | 2 |
| `Tests/OSALinkSharingGateTests.swift` (create) | Suite `osa-sharing-gate` | 2 |
| `Services/Update/UpdateInstallerSupport.swift`, `Services/Update/UpdateService.swift` (modify) | Team id and bundle id injected; notify-only path | 3 |
| `Tests/OSAUpdateTeamTests.swift` (create) | Suite `osa-updates` | 3 |
| `Resources/Info.plist`, `Resources/Vorssaint.entitlements`, `Resources/com.vorssaint.utils.fan-control.plist`, `.github/workflows/ci.yml`, `.github/workflows/release.yml` (modify/rename) | Identity, unsigned CI | 4 |
| `Tools/rebrand.py`, `Tools/test_rebrand.py` (create) | Deterministic rename, two phases | 5 |
| Whole tree (modify, generated) | Output of `rebrand.py --phase visible` then `--phase internal` | 6, 7 |
| `Resources/Brand/AppIcon-Default.png`, `Resources/Brand/logo.png`, `Resources/Brand/AppIcon.icon/` (replace) | Provisional OSA Desktop icon and wordmark | 8 |
| `README.md`, `NOTICE` (create), `TRADEMARKS.md`, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `docs/PRIVACY.md`, `docs/PERMISSIONS.md` | Docs | 9 |
| `Tools/check-rebrand.sh` (create) | AC2/AC3 allowlist check, also run in CI | 9 |

## Decisions

- **Configuration lives in Info.plist**, not in code constants, so a self-hoster or a future signed release only sets environment variables at build time.
- **Two script phases, two commits** (spec "A"): `visible` changes only user-visible text, URLs and bundle ids; `internal` renames identifiers, file and directory names. Reviewers can approve the first without reading 2,700 mechanical identifier changes.
- **String-literal awareness:** inside Swift string literals and in `.strings`/`.plist`/`.md`, the standalone word `Vorssaint` becomes `OSA Desktop`; in code it becomes `OSADesktop`. This avoids identifiers with spaces and avoids user-visible "OSADesktop".
- **Assets with Vorssaint branding in `docs/assets/readme/`** are no longer referenced by the new README. Deleting them follows the owner's rule: list exact files, get approval, then delete (Task 9).
