#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
#  install.sh — link this repo's configuration into your home directory.
#
#      ./install.sh              install (symlinks, backs up what exists)
#      ./install.sh --dry-run    show what would happen, change nothing
#      ./install.sh --uninstall  remove the symlinks, restore backups
#
#  Nothing is hardcoded: the repo location is derived from this script's
#  own path, and every destination honours $XDG_CONFIG_HOME / $HOME.
#  Existing real files are moved to <file>.backup-<timestamp>, never
#  deleted. Existing symlinks pointing here are simply refreshed.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_DIR="${ZJ_BIN_DIR:-$HOME/.local/bin}"
STAMP=$(date +%Y%m%d-%H%M%S)

DRY_RUN=0
UNINSTALL=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help)   sed -n '2,16p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) printf 'Unknown option: %s (try --help)\n' "$arg" >&2; exit 2 ;;
    esac
done

info() { printf '  %s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32m+\033[0m %s\n' "$*"; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# link <source> <destination>
link() {
    local src="$1" dest="$2"

    if [ ! -e "$src" ]; then
        warn "missing in repo, skipped: $src"
        return
    fi

    run mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ]; then
        local current
        current=$(readlink -f "$dest" 2>/dev/null || true)
        if [ "$current" = "$(readlink -f "$src")" ]; then
            info "already linked: $dest"
            return
        fi
        run rm -f "$dest"
    elif [ -e "$dest" ]; then
        run mv "$dest" "$dest.backup-$STAMP"
        warn "backed up existing $dest -> $(basename "$dest").backup-$STAMP"
    fi

    run ln -s "$src" "$dest"
    ok "$dest -> $src"
}

unlink_if_ours() {
    local dest="$1"
    if [ -L "$dest" ] && [[ "$(readlink -f "$dest" 2>/dev/null)" == "$REPO_DIR"* ]]; then
        run rm -f "$dest"
        ok "removed $dest"
        local newest
        newest=$(ls -1d "$dest".backup-* 2>/dev/null | sort | tail -1 || true)
        if [ -n "$newest" ]; then
            run mv "$newest" "$dest"
            info "restored backup $(basename "$newest")"
        fi
    else
        info "not ours, left alone: $dest"
    fi
}

# ── targets ───────────────────────────────────────────────────────────
LINKS=(
    "$REPO_DIR/zellij/config.kdl|$CONFIG_HOME/zellij/config.kdl"
    "$REPO_DIR/zellij/layouts|$CONFIG_HOME/zellij/layouts"
    "$REPO_DIR/zellij/themes|$CONFIG_HOME/zellij/themes"
    "$REPO_DIR/lazygit/config.yml|$CONFIG_HOME/lazygit/config.yml"
    "$REPO_DIR/lazydocker/config.yml|$CONFIG_HOME/lazydocker/config.yml"
)
SCRIPTS=(git-overview zj-logs zj-cd zj-docker)

# ── uninstall ─────────────────────────────────────────────────────────
if [ "$UNINSTALL" -eq 1 ]; then
    step "Removing symlinks"
    for pair in "${LINKS[@]}"; do unlink_if_ours "${pair#*|}"; done
    for s in "${SCRIPTS[@]}"; do unlink_if_ours "$BIN_DIR/$s"; done
    step "Done"
    info "Your lazysql config at $CONFIG_HOME/lazysql/config.toml was left untouched."
    exit 0
fi

# ── install ───────────────────────────────────────────────────────────
step "Repository"
info "$REPO_DIR"
[ "$DRY_RUN" -eq 1 ] && warn "dry run: nothing will be written"

step "Linking configuration"
for pair in "${LINKS[@]}"; do link "${pair%%|*}" "${pair#*|}"; done

step "Linking helper scripts into $BIN_DIR"
run mkdir -p "$BIN_DIR"
for s in "${SCRIPTS[@]}"; do
    run chmod +x "$REPO_DIR/bin/$s"
    link "$REPO_DIR/bin/$s" "$BIN_DIR/$s"
done

step "lazysql connections"
LAZYSQL_DEST="$CONFIG_HOME/lazysql/config.toml"
if [ -e "$LAZYSQL_DEST" ]; then
    info "already present, not touched: $LAZYSQL_DEST"
else
    run mkdir -p "$(dirname "$LAZYSQL_DEST")"
    run cp "$REPO_DIR/lazysql/config.toml.example" "$LAZYSQL_DEST"
    ok "created $LAZYSQL_DEST from the template"
    warn "edit it and replace every CHANGE_ME_* placeholder"
fi
info "This file holds credentials and is deliberately copied, not linked,"
info "so your passwords never end up inside the repository."

step "Checks"
case ":$PATH:" in
    *":$BIN_DIR:"*) ok "$BIN_DIR is on PATH" ;;
    *) warn "$BIN_DIR is NOT on PATH — the layouts will not find the helper scripts."
       info "Add to ~/.bashrc or ~/.zshrc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

command -v zellij >/dev/null 2>&1 \
    && ok "zellij $(zellij --version 2>/dev/null | awk '{print $2}')" \
    || warn "zellij is not installed — see the README"

printf '\n  Optional tools used by the dev layout:\n'
for t in btop lazydocker lazysql lnav lazygit fastfetch neofetch; do
    if command -v "$t" >/dev/null 2>&1; then
        printf '    \033[32m+\033[0m %s\n' "$t"
    else
        printf '    \033[33m-\033[0m %s (missing — the layout falls back gracefully)\n' "$t"
    fi
done

step "Done"
info "Try it with:  zellij --layout dev"
