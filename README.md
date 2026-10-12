<div align="center">

# OSA Desktop

**Dynamic Island and menu bar toolkit for macOS.**

Part of the [Open Software Alliance](https://github.com/OpenSoftwareAlliance) suite.

</div>

---

## Features

- Dynamic Island: music, calendar, timers, downloads and shelf
- Volume mixer and audio routing
- System monitor and fan control
- Window management and app switcher
- Clipboard history and snippets
- Screen capture and recording

## Tech stack

- Swift 6 / AppKit + SwiftUI, macOS 14+ Apple Silicon

## Roadmap

- [Roadmap](docs/specs/ROADMAP.md)
- [Rebrand tracking issue](https://github.com/OpenSoftwareAlliance/vorssaint-utils/issues/21)
- [All issues](https://github.com/OpenSoftwareAlliance/osa-desktop/issues)

## Build from source

```sh
git clone https://github.com/OpenSoftwareAlliance/osa-desktop.git
cd osa-desktop
./build.sh --dev
```

Xcode Command Line Tools are the only requirement. Release builds are unsigned unless `OSA_TEAM_ID` is set, so the app does not install updates itself: it opens the release page instead. Download builds from the [Releases page](https://github.com/OpenSoftwareAlliance/osa-desktop/releases).

## The OSA suite

| Product | What it does | Alternative to |
|---|---|---|
| [OSA Pad](https://github.com/OpenSoftwareAlliance/pad) | Real-time collaborative document editor. | Google Docs |
| [OSA Sheet](https://github.com/OpenSoftwareAlliance/sheet) | Online collaborative spreadsheet. | Google Sheets |
| [OSA Cal](https://github.com/OpenSoftwareAlliance/cal) | Scheduling and booking pages. | Google Calendar (appointment schedules) |
| [OSA Mail](https://github.com/OpenSoftwareAlliance/mail) | Email forwarding and hosting for custom domains. | Gmail |
| [OSA Meet](https://github.com/OpenSoftwareAlliance/meet) | Secure peer-to-peer video meetings. | Google Meet |
| [OSA Draw](https://github.com/OpenSoftwareAlliance/draw) | Infinite canvas whiteboard. | Google Drawings / Jamboard |
| [OSA Drop](https://github.com/OpenSoftwareAlliance/drop) | Local file sharing in the browser. | Quick Share |
| [OSA Share](https://github.com/OpenSoftwareAlliance/share) | Simple temporary file hosting. | Google Drive (file links) |
| [OSA Share Admin](https://github.com/OpenSoftwareAlliance/share-admin) | Moderation panel for OSA Share. | Google Drive admin |
| [OSA Bin](https://github.com/OpenSoftwareAlliance/bin) | Zero-knowledge encrypted pastebin. | Google Keep (secure notes) |
| [OSA Snip](https://github.com/OpenSoftwareAlliance/snip) | Self-hosted code snippets and gists. | Google Keep (snippets) |
| [OSA Short](https://github.com/OpenSoftwareAlliance/short) | URL shortener with analytics. | goo.gl |
| [OSA Alias](https://github.com/OpenSoftwareAlliance/alias) | DNS-based domain redirection. | Google Domains forwarding |
| [OSA Page](https://github.com/OpenSoftwareAlliance/page) | Link-in-bio pages. | Google Sites |
| [OSA Feedback](https://github.com/OpenSoftwareAlliance/feedback) | Feedback boards and public roadmaps. | Google Forms (product feedback) |
| [OSA Jam](https://github.com/OpenSoftwareAlliance/jam) | Live audio rooms. | Google Meet (audio) |
| [OSA Micro](https://github.com/OpenSoftwareAlliance/micro) | Ready-to-use micro service APIs. | Google Cloud APIs |
| [OSA Username](https://github.com/OpenSoftwareAlliance/username) | Check username availability on 100+ sites. | - |
| [OSA Desktop](https://github.com/OpenSoftwareAlliance/osa-desktop) | Dynamic Island and menu bar toolkit for macOS. | - |
| [OSA Status](https://github.com/OpenSoftwareAlliance/status) | Uptime monitor and status page for the OSA services. | - |

## License and credits

OSA Desktop is based on [Vorssaint](https://github.com/vorssaint/vorssaint-utils). Credit for the original work goes to its authors. See [NOTICE](NOTICE).

License: GPL-3.0-or-later. See the [LICENSE](LICENSE) file in this repository.
