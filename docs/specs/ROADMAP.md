# OSA Desktop roadmap

OSA Desktop is the macOS client of the [Open Software Alliance](https://github.com/OpenSoftwareAlliance) suite. It is a hard fork of [Vorssaint](https://github.com/vorssaint/vorssaint-utils) that will absorb the features of [Boring Notch](https://github.com/TheBoredTeam/boring.notch), keeping every existing feature of both.

Each spec below goes through its own spec → plan → implementation → review cycle.

| # | Spec | Depends on | Issues | Status |
|---|---|---|---|---|
| 001 | [Rebrand Vorssaint to OSA Desktop](001-rebrand/spec.md) | — | [#21](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/21) | Spec in review |
| 002 | Reminders | 001 | [#1](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/1) | Not started |
| 003 | Music controls: commands, slots, inactivity timeout, Apple Music lyrics, YouTube Music | 001 | [#3](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/3) [#4](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/4) [#5](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/5) [#6](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/6) [#7](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/7) | Not started |
| 004 | Player visuals: artwork glow, art morph, app badge, slider and accent color | 001 | [#8](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/8) [#9](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/9) | Not started |
| 005 | Shelf tools: context menu, image actions, Quick Share drop zone | 001 | [#10](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/10) [#11](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/11) [#12](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/12) | Not started |
| 006 | Global shortcuts for the island | 001 | [#13](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/13) | Not started |
| 007 | Overlay styles and Option-key action | 001 | [#14](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/14) | Not started |
| 008 | Notch settings parity: calendar options, fullscreen mode, small settings, mirror, battery | 001 | [#2](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/2) [#15](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/15) [#16](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/16) [#17](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/17) [#18](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/18) | Not started |
| 009 | OSA suite integration (OSA Cal, Meet, Drop, Pad; link sharing and feedback on OSA Share) | 001; suite services under `osa.better-web.org` | — | Blocked |

Open decisions: [#19 Intel support](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/19), [#20 extra locales](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/20).

The `boring.notch` fork is archived after 008 is merged. Feature gap analysis: Boring Notch features already covered by Vorssaint (now playing, lyrics, shelf basics, calendar, mirror, HUD replacement, lock screen, gestures) are not ported; its window, media adapter, XPC helper and Sparkle are not ported either.
