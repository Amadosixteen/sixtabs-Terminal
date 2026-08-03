<div align="center">

# sixtabs

**Your entire dev environment. One command. Zero configuration.**

[![License: MIT](https://img.shields.io/badge/license-MIT-2ea44f)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-1793d1)](#-linux-first)
[![Made with: Zellij](https://img.shields.io/badge/made%20with-Zellij-d70a53)](https://zellij.dev)

🇪🇸 [Léelo en español](README.es.md)

</div>

---

You know the ritual. Terminal one for the containers. Terminal two tailing a log.
Terminal three for `git status`, again. Terminal four... where was terminal four?

This repo replaces the ritual with a keystroke:

```
zdev
```

```
┃ monitor ┃ docker ┃ db ┃ logs ┃ git ┃ projects ┃
```

Six tabs. Everything already running, already pointed at your work:

|   | Tab | What's waiting for you |
|---|-----|------------------------|
| 📈 | **monitor** | CPU, memory, disks, network, processes — live |
| 🐳 | **docker** | Every container: logs, restart, shell in, stats |
| 🗄️ | **db** | Your databases in a full TUI client |
| 📜 | **logs** | Your app's log, streaming, searchable |
| 🌿 | **git** | Every repo's branch and dirty state, refreshed every 5s |
| 🚀 | **projects** | A shell, already `cd`'d where your code lives |

No absolute paths. No hardcoded projects. No credentials.
Clone it on any Linux machine and it just... fits.

## Get it

```bash
git clone https://github.com/Amadosixteen/sixtabs-Terminal.git
cd sixtabs-Terminal
./install.sh
```

That's the whole setup. `./install.sh --dry-run` first if you like watching
before touching — and everything it replaces is backed up, never deleted.
`./install.sh --uninstall` puts it all back.

`zdev` is one of the helper scripts the installer links into `~/.local/bin`.
It attaches to a single session named `dev`, creating it only if it is not
already running. That matters more than it sounds: `zellij --layout dev`
mints a *new* randomly-named session every time, Zellij never reaps detached
ones, and the panes inside a session nobody is attached to keep running. Run
it once per terminal for an afternoon and you are quietly paying for a dozen
workspaces you cannot see.

Only [Zellij](https://zellij.dev) is required. Everything else is optional:

> btop · lazydocker · lazysql · lnav · lazygit

Missing one? The pane tells you what it would do, how to get it, and hands you
a working shell instead. **Nothing here ever dies silently** — that's the
design rule the whole repo is built around. Even the classic
*"docker works for root but not for me"* trap gets detected, explained, and
in most cases fixed automatically.

## Make it yours

Two optional variables. That's the entire configuration surface:

```bash
export ZJ_PROJECTS_DIR="$HOME/code"     # where your repos live
export ZJ_LOG_FILE="/path/to/app.log"   # a specific log to follow
```

Set neither, and it finds `~/Projects` and your most recent log on its own.

## 🐧 Linux first

Built for Linux, tested on Linux. macOS mostly works. **WSL2 runs it with
obstacles** (Docker socket, clipboard, fonts) — honestly documented, not
hand-waved. Native Windows: no.

Details, internals and troubleshooting live in the **[Guide](docs/GUIDE.md)**.

---

<div align="center">

MIT — take it, break it, make it yours.

</div>
