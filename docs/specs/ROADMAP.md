# OSA Desktop roadmap

OSA Desktop is the macOS client of the [Open Software Alliance](https://github.com/OpenSoftwareAlliance) suite. It is a hard fork of [Vorssaint](https://github.com/vorssaint/vorssaint-utils) that will absorb [Boring Notch](https://github.com/TheBoredTeam/boring.notch), keeping every existing feature of both.

Each spec below goes through its own spec → plan → implementation → review cycle.

| # | Spec | Depends on | Status |
|---|---|---|---|
| 001 | [Rebrand Vorssaint to OSA Desktop](001-rebrand/spec.md) | — | Spec in review |
| 002 | Port Boring Notch features into OSA Desktop; archive the `boring.notch` fork | 001 | Not started (feature gap analysis in progress) |
| 003 | OSA suite integration: notch and menu bar connected to OSA Cal, Meet, Drop, Pad; link sharing and feedback backend on OSA Share | 001; suite services with domains and APIs under `osa.better-web.org` | Blocked |
