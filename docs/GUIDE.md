# The Guide

Everything the [README](../README.md) deliberately left out. 🇪🇸 [Versión en español](GUIA.es.md)

- [How it's put together](#how-its-put-together)
- [The helper scripts](#the-helper-scripts)
- [Configuration reference](#configuration-reference)
- [Credentials](#credentials)
- [Platform notes (Linux / macOS / WSL2)](#platform-notes)
- [Design decisions worth knowing](#design-decisions-worth-knowing)
- [Troubleshooting](#troubleshooting)

## How it's put together

```
.
├── install.sh                    symlink installer (--dry-run, --uninstall)
├── bin/
│   ├── git-overview              git status table for a folder of repos
│   ├── zj-logs                   log viewer with discovery + fallbacks
│   ├── zj-cd                     shell in the projects directory
│   └── zj-docker                 Docker TUI with a daemon-reachability check
├── zellij/
│   ├── config.kdl                only what differs from Zellij's defaults
│   ├── layouts/dev.kdl           the six-tab workspace
│   └── themes/debian.kdl         "debian" (red accent) and "tango"
├── lazygit/config.yml
├── lazydocker/config.yml
└── lazysql/config.toml.example   template — the real file is git-ignored
```

The installer symlinks configs into `$XDG_CONFIG_HOME` (or `~/.config`) and the
four scripts into `~/.local/bin`. Anything already present is moved to
`<file>.backup-<timestamp>`, never deleted. Re-running is safe;
`--uninstall` removes the symlinks and restores the newest backup of each file.

### Why not `$VAR` directly in the layout?

Zellij's KDL parser does **not** expand environment variables in `cwd` or
`args`. That is the reason most published layouts end up with somebody's home
directory baked in. Here, anything needing a runtime value is either wrapped in
`sh -c` (where the shell expands it) or delegated to a script in `bin/`. Panes
with no `cwd` inherit the directory you launched `zellij` from.

## The helper scripts

All four work standalone, outside Zellij.

**`git-overview [dir]`** — table of branch, last commit and dirty-file count
for every git repository directly under `dir`. Lists repository *roots* only,
so it stays correct when the folder itself sits inside a repo.

**`zj-logs [file]`** — opens a log in the best available viewer
(`lnav` → `less +F` → `tail -F`). With no argument it uses `$ZJ_LOG_FILE`,
otherwise the most recently modified `*.log` under the projects dir (depth 4).
Finds nothing? It prints instructions and drops to a shell instead of exiting.

**`zj-cd [dir]`** — interactive shell in the projects directory.

**`zj-docker`** — checks that the Docker daemon is actually reachable before
starting `lazydocker`, and names the cause when it is not. See
[the `docker` group trap](#the-docker-group-trap) below for the interesting case.

## Configuration reference

| Variable | Default | Used by |
|---|---|---|
| `ZJ_PROJECTS_DIR` | `~/Projects`, else the current directory | `git` and `projects` tabs, `git-overview`, `zj-logs` search root |
| `ZJ_LOG_FILE` | newest `*.log` under `ZJ_PROJECTS_DIR` (depth 4) | `logs` tab |
| `ZJ_BIN_DIR` | `~/.local/bin` | where `install.sh` links the scripts |

Set them in your shell profile, or per invocation:

```bash
ZJ_LOG_FILE=/var/log/syslog zellij --layout dev
```

A handy alias if you use the workspace daily:

```bash
alias zdev='zellij --layout dev'
```

## Credentials

`lazysql/config.toml.example` is a template. The installer copies it to
`~/.config/lazysql/config.toml` **only if that file does not already exist**,
and the real file is git-ignored, because lazysql stores connection URLs as
`provider://user:password@host:port/db` in plain text.

Copied, not symlinked — deliberately. A symlink would put your passwords inside
the repository working tree, one `git add -A` away from being published.

If you ever commit one by accident, rotate those passwords. Deleting the file
in a later commit does not remove it from git history.

## Platform notes

### Linux 🐧

First-class. Developed and tested on Linux (Mint/Ubuntu family); nothing is
distro-specific — `/etc/os-release`, `getent` and GNU coreutils are the only
assumptions.

### macOS

Mostly works. The scripts already carry BSD fallbacks (`stat -f` in `zj-logs`),
and the clipboard note in `zellij/config.kdl` covers `pbcopy`. Install the
optional tools with Homebrew. Not regularly tested — reports welcome.

### WSL2 — runs, with obstacles

It works, but expect friction. Known obstacles, in the order you will hit them:

1. **Docker.** There is no `dockerd` inside a stock WSL2 distro. Either enable
   *Docker Desktop → Settings → Resources → WSL integration* for your distro,
   or install Docker Engine natively inside WSL2 (needs systemd enabled in
   `/etc/wsl.conf`). Until then the `docker` tab will diagnose "cannot reach
   the daemon" — which is accurate.
2. **Clipboard.** Zellij copies via OSC 52, which Windows Terminal supports —
   but only from focused panes, and some terminals (ConEmu, older mintty) do
   not support it at all. If copying fails, `wl-copy`/`xclip` won't save you
   without WSLg; `clip.exe` works: `copy_command "clip.exe"` in `config.kdl`.
3. **Fonts.** The tab bar's powerline glyphs need a Nerd Font *configured in
   Windows Terminal*, not inside WSL. Or set `simplified_ui true`.
4. **Performance.** Keep your repos inside the WSL filesystem (`~/...`), not
   under `/mnt/c`. The `git` tab re-runs `git status` on every repo every 5
   seconds, and 9P filesystem access makes that painfully slow.

Native Windows (PowerShell/cmd): not supported. The scripts are POSIX shell.

## Design decisions worth knowing

`zellij/config.kdl` is deliberately short. Three choices are worth explaining,
because each is a common way a Zellij setup ends up feeling broken:

- **`session_serialization false`.** Zellij's default saves the live layout to
  `~/.cache/zellij` and resurrects it on the next run. While you are editing
  layouts this means your `.kdl` changes appear to do nothing — you keep
  getting the old session back, with dead panes marked `start_suspended true`.
  Turn it on again once your layouts are stable.
- **`default_layout "default"`.** Setting a heavy workspace as the default
  makes *every* new terminal spawn the full monitoring stack. Launch it
  explicitly (or via the `zdev` alias) instead.
- **No `keybinds` block.** Zellij's configuration plugin writes the entire
  default keybind table into your config when it saves — roughly 250 lines
  that change nothing and bury real customizations. Run
  `zellij setup --dump-config` when you want to read the defaults.

**One pane per tab** in `monitor`: btop refuses to draw below 80×16, so
sharing a ~120-column window with anything else starves it into
"Terminal size too small". With the whole tab it renders even at 80×24.

### The `docker` group trap

Supplementary groups are assigned when a process is created and cannot be
added to a running one. If your login session started before
`usermod -aG docker` ran, every shell it spawns lacks the group — while `id`
cheerfully reports you as a member. Opening a "new" terminal window usually
does not help either: new windows attach to the same long-lived terminal
server process.

`zj-docker` compares the process's real groups (`id -G`) against the
account's (`id -nG`). When only the process lacks it, it re-executes itself
through `sg docker` — setuid, so it can grant the group — which usually fixes
the pane with no logout. One retry, bounded by a guard variable; if that
still fails it prints the remaining fixes in order of thoroughness.

## Troubleshooting

**My layout edits do nothing.** Session serialization is resurrecting an old
session. Check `zellij list-sessions`, then `zellij delete-all-sessions`
(or delete them one by one), or clear `~/.cache/zellij`.

**Panes appear dead / suspended.** The pane's command exited — press `Enter`
inside it to rerun. If it happens on every start, a tool or path is missing;
every pane in this repo prints why.

**Helper scripts not found.** `~/.local/bin` is not on your `PATH`. Add
`export PATH="$HOME/.local/bin:$PATH"` to your shell profile.

**Copying does not reach the system clipboard.** Uncomment the `copy_command`
line matching your session in `zellij/config.kdl` (`xclip` for X11, `wl-copy`
for Wayland, `pbcopy` for macOS, `clip.exe` for WSL2).

**Icons render as boxes.** Use a Nerd Font, or set `simplified_ui true` in
`zellij/config.kdl`.

**lnav starts with a wall of "permission denied".** Your
`~/.config/lnav/formats/default/` files lost their write bit (this can happen
when configs are migrated between machines with `tar`). Fix:
`chmod -R u+w ~/.config/lnav` — or delete `formats/default` and
`configs/default`; lnav regenerates them.

**The db tab shows stale connections.** lazysql lists whatever is saved in
`~/.config/lazysql/config.toml` — that file is yours, not the repo's. Edit it
to remove connections whose services no longer exist.
