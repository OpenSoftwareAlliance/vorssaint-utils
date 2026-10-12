# 001: Rebrand Vorssaint to OSA Desktop

## Why

This repository is a fork of Vorssaint (GPL-3.0-or-later). The license covers the source code only. Vorssaint's [TRADEMARKS.md](../../../TRADEMARKS.md) requires forks to use a different name, app icon, bundle identifier, signing identity, update feed and any branding that could imply endorsement. The fork also depends on Vorssaint-operated infrastructure (`screenshots.vorssaint.com`, Vorssaint's GitHub releases and raw files), which a fork must not use on its users' behalf.

OSA Desktop is a hard fork: it will not track Vorssaint upstream after this change. Renaming internal identifiers is therefore a one-time cost that keeps the codebase coherent for future contributors.

## What

Turn the fork into **OSA Desktop** without adding, removing or changing any feature behavior.

### Identity mapping

| Item | From | To |
|---|---|---|
| GitHub repo | `OpenSoftwareAlliance/vorssaint-utils` | `OpenSoftwareAlliance/osa-desktop` |
| App name | Vorssaint / Vorssaint (Developer) | OSA Desktop / OSA Desktop (Developer) |
| Executable | `Vorssaint` / `VorssaintDeveloper` | `OSADesktop` / `OSADesktopDeveloper` |
| Bundle id | `com.vorssaint.utils` (`.dev` for developer builds) | `org.better-web.osa.desktop` (`.dev` for developer builds) |
| Fan control helper | `com.vorssaint.utils.fan-control` | `org.better-web.osa.desktop.fan-control` |
| Swift sources dir | `Sources/Vorssaint` | `Sources/OSADesktop` |
| Compile flag | `VORSSAINT_DEVELOPMENT` | `OSA_DESKTOP_DEVELOPMENT` |
| Internal identifiers | `Vorssaint…` / `vorssaint…` (types, defaults keys, notification names, pasteboard types) | `OSADesktop…` / `osaDesktop…` |
| App icon and logo | Vorssaint icon drawn by `Tools/MakeIcon.swift` | Provisional OSA Desktop logo generated with Codex CLI, built into the iconset by `Tools/MakeIcon.swift` |
| In-app update source | GitHub releases of `vorssaint/vorssaint-utils` | GitHub releases of `OpenSoftwareAlliance/osa-desktop` |
| AI agent price list | raw file in `vorssaint/vorssaint-utils` | raw file in `OpenSoftwareAlliance/osa-desktop` |
| Link sharing (screenshots, recordings) and feedback | `https://screenshots.vorssaint.com` | Configurable endpoint `OSAShareEndpoint` in `Info.plist`, empty by default |
| Website and support links | vorssaint.com, Discord, Buy Me a Coffee, hello@vorssaint.com | `https://osa.better-web.org`, GitHub Issues of `OpenSoftwareAlliance/osa-desktop` |
| Signing and notarization | Vorssaint Developer ID, team `3D485NHW29` hardcoded in `release.yml` and `UpdateInstallerSupport.swift` | Team id and signing identity read from one build setting (`OSA_TEAM_ID`), unset by default; builds and release DMGs are unsigned |
| In-app update install | Installs a downloaded DMG only if signed by team `3D485NHW29` | If `OSA_TEAM_ID` is set: same verification against that team. If unset: notify and open the release page; never auto-install unsigned code |
| README | Vorssaint README | OSA standard README (same template as the other OSA repos) |
| TRADEMARKS.md | Vorssaint policy | OSA policy with the same rule for forks of OSA Desktop |
| Credits | — | `NOTICE` stating the fork origin and crediting Vorssaint; README credits section |

### Requirements

1. **R1 Identity.** Every user-visible name, bundle id, icon, URL and support channel follows the mapping above, in all localizations.
2. **R2 No Vorssaint infrastructure.** No code path sends requests to `*.vorssaint.com` or reads from `vorssaint/*` repositories.
3. **R3 Link sharing and feedback gated.** When `OSAShareEndpoint` is empty, the "share by link" actions for screenshots and recordings and the in-app feedback form are hidden; all other sharing (Share menu, files, clipboard) keeps working. When it is set to a URL, those features use it. The implementation code is kept.
4. **R4 Internal rename.** Internal identifiers are renamed by a committed, deterministic script (`Tools/rebrand.py`). Re-running it on the result is a no-op. Copyright notice lines are never modified.
5. **R5 Unsigned builds.** `build.sh`, `ci.yml` and `release.yml` produce unsigned builds and DMGs without requiring any certificate or secret. Signing and notarization run only when `OSA_TEAM_ID` and the signing secrets are present.
6. **R6 Docs.** README, NOTICE, TRADEMARKS, CONTRIBUTING, SECURITY, SUPPORT, PRIVACY and PERMISSIONS refer to OSA Desktop and OSA channels.
7. **R7 Safe updates.** The team id used by the in-app installer comes from `OSA_TEAM_ID` baked at build time. With no team id, the updater checks `OpenSoftwareAlliance/osa-desktop` releases, notifies the user and opens the release page instead of installing.

### Acceptance criteria

- **AC1.** A baseline of `./build.sh` and `./build.sh --test` is recorded on the unmodified fork before any change. After the rebrand, both produce the same result as the baseline (same pass/fail set, apart from tests renamed by the script).
- **AC2.** `git grep -i vorssaint` matches only an explicit allowlist: copyright notice lines (`Copyright (C) … Vorssaint`, which must be preserved under the GPL), `LICENSE`, historical `CHANGELOG.md` entries, `NOTICE`, the README credits section, `docs/specs/**`, and the rebrand tooling (`Tools/rebrand.py`, `Tools/test_rebrand.py`, `Tools/check-rebrand.sh`).
- **AC3.** `git grep -i 'vorssaint.com'` outside the allowlist returns nothing (R2).
- **AC4.** A test covers R3 in both states (endpoint empty → sharing-by-link and feedback hidden; endpoint set → available).
- **AC5.** Running `Tools/rebrand.py` a second time changes no files.
- **AC6.** The developer build launches as "OSA Desktop (Developer)" with bundle id `org.better-web.osa.desktop.dev` and the new icon, verified by launching it and capturing a screenshot. Report states which features were exercised by hand and which were only covered by build/tests (per `docs/AI-CONTRIBUTIONS.md`).
- **AC7.** CI (`ci.yml`) passes on the PR without signing secrets.
- **AC8.** A test covers R7: with no team id, the update flow resolves to "open release page"; with a team id, the verification requirement contains that team id and the new bundle id. `git grep 3D485NHW29` returns nothing.

## Out of scope

- Porting Boring Notch features (specs 002-008).
- A backend for link sharing and feedback, and any integration with OSA services (spec 009).
- Obtaining a Developer ID certificate, notarization, publishing a signed release, hosting an update feed.
- Any new feature, UI redesign or behavior change.
- Migrating existing Vorssaint user preferences: the new bundle id starts with fresh preferences and permissions by design.

## Decisions

- Base for the merged app is Vorssaint (larger, modular, already has Dynamic Island and Shelf).
- Hard fork; no upstream sync after this spec.
- Bundle id prefix `org.better-web.osa` follows the OSA domain `osa.better-web.org`.
- The logo is provisional, generated with Codex CLI, until an OSA visual identity exists.
