# zellij-config

A portable [Zellij](https://zellij.dev) workspace plus matching configuration for
`lazygit`, `lazydocker` and `lazysql`. No absolute paths, no personal
directories, no credentials — clone it on any Linux or macOS machine and it
works, or degrades with a clear message instead of a dead pane.

> 🇪🇸 Documentación en español: [README.es.md](README.es.md)

```
zellij --layout dev
```

## What you get

| Tab | Contents | Falls back to |
|---|---|---|
| `system` | host summary, CPU graph, full resource monitor | `fastfetch` → `neofetch` → `uname`; `btop` → `htop` → `top` |
| `docker` | interactive container management | `lazydocker` → `docker stats` → shell |
| `db` | database TUI client | `lazysql` → shell with install hint |
| `logs` | follows an application log | `lnav` → `less +F` → `tail -F` |
| `git` | one-line status of every repo in your projects folder, plus a shell | shell |
| `projects` | a plain shell in your projects folder | current directory |

## Requirements

Only **Zellij** is required. Everything else is optional — each pane checks for
its tool and explains itself if it is missing.

```bash
# Zellij (see https://zellij.dev/documentation/installation for all options)
cargo install --locked zellij
# or: brew install zellij  /  pacman -S zellij  /  download a release binary
```

Optional, in rough order of usefulness:
[`btop`](https://github.com/aristocratos/btop),
[`lazygit`](https://github.com/jesseduffield/lazygit),
[`lazydocker`](https://github.com/jesseduffield/lazydocker),
[`lnav`](https://lnav.org),
[`lazysql`](https://github.com/jorgerojas26/lazysql),
[`fastfetch`](https://github.com/fastfetch-cli/fastfetch).

## Install

```bash
git clone https://github.com/<you>/zellij-config.git
cd zellij-config
./install.sh --dry-run     # see exactly what would change
./install.sh
```

The installer symlinks into `$XDG_CONFIG_HOME` (or `~/.config`) and puts three
helper scripts in `~/.local/bin`. Anything already there is **moved to
`<file>.backup-<timestamp>`**, never deleted. Re-running is safe.

`./install.sh --uninstall` removes the symlinks and restores the most recent
backup of each file.

## Configuration

Everything is driven by two optional environment variables. Set them in your
shell profile, or per invocation.

| Variable | Default | Used by |
|---|---|---|
| `ZJ_PROJECTS_DIR` | `~/Projects`, else the current directory | `git` and `projects` tabs, `git-overview` |
| `ZJ_LOG_FILE` | newest `*.log` under `ZJ_PROJECTS_DIR` (depth 4) | `logs` tab |

```bash
export ZJ_PROJECTS_DIR="$HOME/code"
ZJ_LOG_FILE=/var/log/syslog zellij --layout dev
```

If neither is set, panes simply inherit the directory you launched `zellij`
from — so `cd ~/some-project && zellij --layout dev` does the sensible thing
with no configuration at all.

### Why not `$VAR` directly in the layout?

Zellij's KDL parser does **not** expand environment variables in `cwd` or
`args`. That is the reason most published layouts end up with somebody's home
directory baked in. Here, anything needing a runtime value is either wrapped in
`sh -c` (where the shell expands it) or delegated to a script in `bin/`. Panes
with no `cwd` inherit the session's working directory.

## Helper scripts

All three work standalone, outside Zellij.

- **`git-overview [dir]`** — table of branch, last commit and dirty-file count
  for every git repository directly under `dir`. Lists repository *roots* only,
  so it stays correct when the folder itself is inside a repo.
- **`zj-logs [file]`** — opens a log in the best available viewer. With no
  argument it uses `$ZJ_LOG_FILE`, otherwise the most recently modified `*.log`
  it can find. Prints instructions and drops to a shell rather than exiting.
- **`zj-cd [dir]`** — starts an interactive shell in the projects directory.

## Credentials

`lazysql/config.toml.example` is a template. The installer copies it to
`~/.config/lazysql/config.toml` **only if that file does not already exist**,
and the real file is git-ignored, because lazysql stores connection URLs as
`provider://user:password@host:port/db` in plain text.

Copied, not symlinked — deliberately. A symlink would put your passwords inside
the repository working tree, one `git add -A` away from being published.

If you ever commit one by accident, rotate those passwords. Deleting the file in
a later commit does not remove it from git history.

## Notes on the Zellij config

`zellij/config.kdl` is deliberately short. Three choices are worth explaining,
because each one is a common way a Zellij setup ends up feeling broken:

- **`session_serialization false`.** Zellij's default is to save the live layout
  to `~/.cache/zellij` and resurrect it on the next run. While you are editing
  layouts this means your `.kdl` changes appear to do nothing — you keep getting
  the old session back, with dead command panes marked `start_suspended true`.
  Turn it on again once your layouts are stable.
- **`default_layout "default"`.** Setting a heavy workspace as the default makes
  *every* new terminal spawn a monitoring stack — easily eight extra processes
  per session. Launch it explicitly with `zellij --layout dev` instead.
- **No `keybinds` block.** Zellij's configuration plugin writes the entire
  default keybind table into your config when it saves — roughly 250 lines that
  change nothing and bury any real customization. Run
  `zellij setup --dump-config` when you want to read the defaults; only add a
  `keybinds` block here for bindings you actually change.

## Troubleshooting

**My layout edits do nothing.** Session serialization is resurrecting an old
session. Confirm with `zellij list-sessions`, then
`zellij delete-all-sessions`, or clear `~/.cache/zellij`.

**Panes appear dead / suspended.** The pane's command exited. Press `Enter`
inside it to rerun. If it happens on every start, the command or a path it
needs is missing — every pane in this repo prints why.

**Helper scripts not found.** `~/.local/bin` is not on your `PATH`. Add
`export PATH="$HOME/.local/bin:$PATH"` to your shell profile.

**Copying does not reach the system clipboard.** Zellij uses OSC 52 by default,
which some terminals do not support. Uncomment the `copy_command` line matching
your session in `zellij/config.kdl` (`xclip` for X11, `wl-copy` for Wayland,
`pbcopy` for macOS).

**Icons render as boxes.** Set `simplified_ui true` in `zellij/config.kdl`, or
use a Nerd Font.

## Layout

```
.
├── install.sh                    symlink installer (--dry-run, --uninstall)
├── bin/
│   ├── git-overview              git status table for a folder of repos
│   ├── zj-logs                   log viewer with discovery + fallbacks
│   └── zj-cd                     shell in the projects directory
├── zellij/
│   ├── config.kdl                only what differs from the defaults
│   ├── layouts/dev.kdl           the six-tab workspace
│   └── themes/debian.kdl         "debian" (red accent) and "tango"
├── lazygit/config.yml
├── lazydocker/config.yml
└── lazysql/config.toml.example   template — real file is git-ignored
```

## License

MIT — see [LICENSE](LICENSE).
