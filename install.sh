#!/usr/bin/env bash
#
# install.sh — installer for the Noctalia + Hyprland/niri "rice" dotfiles.
#
# What it does:
#   1. Asks which compositor config you want (Hyprland, niri, or both)
#   2. Checks that the dependencies for that selection are installed
#   3. Backs up any existing configs it is about to replace
#   4. Symlinks (never copies) the shared/ folder plus the chosen compositor
#      folder(s) into the right ~/.config locations
#   5. Optionally seeds a Noctalia settings.toml if you don't have one yet
#
# It is safe to re-run: existing symlinks pointing at this repo are left alone
# and everything else is backed up before being replaced.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Paths & flags
# ---------------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
BIN_DIR="$HOME/.local/bin"
WALLPAPER_DIR="$HOME/Pictures/dotfiles-wallpapers"
BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
ASSUME_YES=0
SKIP_DEPS=0
CHOICE=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --hyprland        Install Hyprland config + shared configs (no prompt)
  --niri            Install niri config + shared configs (no prompt)
  --both            Install both compositors + shared configs (no prompt)
  --dry-run         Show what would happen, change nothing
  -y, --yes         Don't ask for confirmation
  --skip-deps       Don't check for dependencies
  -h, --help        Show this help

With no compositor flag, install.sh interactively asks which one you want.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --hyprland|--hypr)  CHOICE=hyprland ;;
    --niri)             CHOICE=niri ;;
    --both)             CHOICE=both ;;
    --dry-run)          DRY_RUN=1 ;;
    -y|--yes)           ASSUME_YES=1 ;;
    --skip-deps)        SKIP_DEPS=1 ;;
    -h|--help)          usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage; exit 1 ;;
  esac
  shift
done

say()  { printf '%s\n' "$*"; }
info() { printf '\033[34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m  ok\033[0m %s\n' "$*"; }
warn() { printf '\033[33m  !!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; }

confirm() {
  [ "$ASSUME_YES" = 1 ] && return 0
  if [ ! -t 0 ]; then
    err "not running on a TTY; re-run with --yes to confirm non-interactively"
    return 1
  fi
  printf '%s [y/N] ' "$1"
  read -r reply
  case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}


# ---------------------------------------------------------------------------
# Dependency metadata — command name -> package name, per distro
# ---------------------------------------------------------------------------
declare -A PKG_FEDORA=(
  [hyprland]=hyprland            [Hyprland]=hyprland
  [hyprctl]=hyprland             [hyprlock]=hyprlock
  [niri]=niri
  [noctalia]=noctalia
  [kitty]=kitty                  [fuzzel]=fuzzel
  [btop]=btop                    [nautilus]=nautilus
  [playerctl]=playerctl          [brightnessctl]=brightnessctl
  [wpctl]=wireplumber            [wl-copy]=wl-clipboard
  [grim]=grim                    [slurp]=slurp
  [swaylock]=swaylock
  [dbus-update-activation-environment]=dbus-tools
  [xdg-desktop-portal-hyprland]=xdg-desktop-portal-hyprland
  [xfce-polkit]=xfce-polkit
)
declare -A PKG_ARCH=(
  [hyprland]=hyprland            [Hyprland]=hyprland
  [hyprctl]=hyprland             [hyprlock]=hyprlock
  [niri]=niri
  [noctalia]=noctalia
  [kitty]=kitty                  [fuzzel]=fuzzel
  [btop]=btop                    [nautilus]=nautilus
  [playerctl]=playerctl          [brightnessctl]=brightnessctl
  [wpctl]=wireplumber            [wl-copy]=wl-clipboard
  [grim]=grim                    [slurp]=slurp
  [swaylock]=swaylock
  [dbus-update-activation-environment]=dbus
  [xdg-desktop-portal-hyprland]=xdg-desktop-portal-hyprland
  [xfce-polkit]=xfce-polkit
)

COMMON_CMDS=(noctalia kitty fuzzel btop nautilus playerctl brightnessctl
             wpctl wl-copy grim slurp)
HYPR_CMDS=(hyprland hyprctl hyprlock xdg-desktop-portal-hyprland
           dbus-update-activation-environment)
NIRI_CMDS=(niri)

selected_cmds() {
  printf '%s\n' "${COMMON_CMDS[@]}"
  case "$CHOICE" in
    hyprland) printf '%s\n' "${HYPR_CMDS[@]}" ;;
    niri)     printf '%s\n' "${NIRI_CMDS[@]}" ;;
    both)     printf '%s\n' "${HYPR_CMDS[@]}" "${NIRI_CMDS[@]}" ;;
  esac
}

detect_pkg_manager() {
  if command -v dnf >/dev/null 2>&1;        then echo dnf
  elif command -v apt-get >/dev/null 2>&1;  then echo apt
  elif command -v pacman >/dev/null 2>&1;   then echo pacman
  elif command -v zypper >/dev/null 2>&1;   then echo zypper
  else echo unknown; fi
}

pkg_name_for() {
  local cmd="$1"
  case "$(detect_pkg_manager)" in
    dnf)    echo "${PKG_FEDORA[$cmd]:-$cmd}" ;;
    pacman) echo "${PKG_ARCH[$cmd]:-$cmd}" ;;
    *)      echo "$cmd" ;;
  esac
}

check_deps() {
  info "Checking dependencies for: $CHOICE"
  local missing="" cmd pkg
  local -A seen=()

  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    command -v "$cmd" >/dev/null 2>&1 && continue
    pkg="$(pkg_name_for "$cmd")"
    if [ -z "${seen[$pkg]:-}" ]; then
      seen[$pkg]=1
      missing="$missing $pkg"
    fi
  done < <(selected_cmds)

  # xfce-polkit lives in libexec, so it is not on $PATH
  if { [ "$CHOICE" = niri ] || [ "$CHOICE" = both ]; } \
     && [ ! -x /usr/libexec/xfce-polkit ] && [ ! -x /usr/lib/xfce-polkit ]; then
    if [ -z "${seen[xfce-polkit]:-}" ]; then
      missing="$missing xfce-polkit"
      seen[xfce-polkit]=1
    fi
  fi

  # kitty's configured font (kitty silently falls back if it is missing)
  if ! fc-match "Source Code Pro" 2>/dev/null | grep -qi "Source Code Pro"; then
    warn "font 'Source Code Pro' not found (kitty will fall back to monospace)"
    case "$(detect_pkg_manager)" in
      dnf)    missing="$missing adobe-source-code-pro-fonts" ;;
      pacman) missing="$missing adobe-source-code-pro-fonts" ;;
      apt)    missing="$missing fonts-adobe-source-code-pro" ;;
    esac
  fi

  if [ -n "$(printf '%s' "$missing" | tr -d ' ')" ]; then
    warn "missing packages:$missing"
    case "$(detect_pkg_manager)" in
      dnf)    say "    install with: sudo dnf install$missing" ;;
      pacman) say "    install with: sudo pacman -S$missing" ;;
      apt)    say "    install with: sudo apt install$missing" ;;
      zypper) say "    install with: sudo zypper install$missing" ;;
      *)      say "    install these with your package manager." ;;
    esac
    say "    (Noctalia / niri / hyprlock may need a COPR, AUR or a"
    say "     third-party repo on your distro — see README.md.)"
    if ! confirm "Continue anyway?"; then
      err "aborting: install the dependencies first, or pass --skip-deps"
      exit 1
    fi
  else
    ok "all required commands found"
  fi
}

# ---------------------------------------------------------------------------
# Backup / symlink helpers
# ---------------------------------------------------------------------------
backup_path() {
  local target="$1" rel dest
  [ -e "$target" ] || [ -L "$target" ] || return 0
  rel="${target#"$HOME"/}"
  dest="$BACKUP_ROOT/$rel"
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  warn "backed up: $target -> $dest"
}

# link_path <src-in-repo> <target-path>
link_path() {
  local src="$1" target="$2"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    ok "already linked: $target"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    say "  [dry-run] would link $target -> $src"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  backup_path "$target"
  ln -s "$src" "$target"
  ok "linked: $target -> $src"
}

# link_into_dir <src-dir-in-repo> <target-dir>
# Symlinks each file individually, leaving unrelated files in the target
# directory alone (used for gtk-3.0 / gtk-4.0, which also hold personal data
# such as file bookmarks).
link_into_dir() {
  local srcdir="$1" destdir="$2" f rel
  say "  linking files into: $destdir"
  while IFS= read -r -d '' f; do
    rel="${f#"$srcdir"/}"
    link_path "$f" "$destdir/$rel"
  done < <(find "$srcdir" -type f -print0 | sort -z)
}

# ---------------------------------------------------------------------------
# Install steps
# ---------------------------------------------------------------------------
install_shared() {
  info "Linking shared configs"
  link_path "$REPO_DIR/shared/noctalia"  "$CONFIG_DIR/noctalia"
  link_path "$REPO_DIR/shared/kitty"     "$CONFIG_DIR/kitty"
  link_path "$REPO_DIR/shared/fuzzel"    "$CONFIG_DIR/fuzzel"
  link_path "$REPO_DIR/shared/btop"      "$CONFIG_DIR/btop"
  link_path "$REPO_DIR/shared/qt5ct"     "$CONFIG_DIR/qt5ct"
  link_path "$REPO_DIR/shared/qt6ct"     "$CONFIG_DIR/qt6ct"
  link_into_dir "$REPO_DIR/shared/gtk-3.0" "$CONFIG_DIR/gtk-3.0"
  link_into_dir "$REPO_DIR/shared/gtk-4.0" "$CONFIG_DIR/gtk-4.0"
  link_path "$REPO_DIR/shared/wallpapers" "$WALLPAPER_DIR"

  info "Linking helper scripts into $BIN_DIR"
  if [ "$DRY_RUN" != 1 ]; then
    mkdir -p "$BIN_DIR"
  fi
  local s
  for s in "$REPO_DIR"/shared/scripts/*.sh; do
    [ -e "$s" ] || continue
    if [ "$DRY_RUN" != 1 ]; then
      chmod +x "$s"
    fi
    link_path "$s" "$BIN_DIR/$(basename "$s")"
  done
}

install_compositor() {
  case "$CHOICE" in
    hyprland)
      info "Linking Hyprland config"
      link_path "$REPO_DIR/hypr" "$CONFIG_DIR/hypr"
      ;;
    niri)
      info "Linking niri config"
      link_path "$REPO_DIR/niri" "$CONFIG_DIR/niri"
      ;;
    both)
      info "Linking Hyprland + niri configs"
      link_path "$REPO_DIR/hypr" "$CONFIG_DIR/hypr"
      link_path "$REPO_DIR/niri" "$CONFIG_DIR/niri"
      ;;
  esac
}

# Never overwrite live Noctalia runtime state — only seed it when absent.
seed_noctalia_settings() {
  local src="$REPO_DIR/shared/noctalia/settings.toml.example"
  local dst="$STATE_DIR/noctalia/settings.toml"
  [ -f "$src" ] || return 0

  if [ -f "$dst" ]; then
    ok "kept existing Noctalia settings: $dst"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    say "  [dry-run] would seed $dst from settings.toml.example"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  sed "s|@HOME@|${HOME//|/\\|}|g" "$src" > "$dst"
  ok "seeded Noctalia settings: $dst"
}

choose_compositor() {
  [ -n "$CHOICE" ] && return 0

  if [ ! -t 0 ]; then
    err "no compositor selected and not running on a TTY."
    err "Use --hyprland, --niri or --both."
    exit 1
  fi

  say ""
  say "Which configuration do you want to install?"
  say "  1) Hyprland only"
  say "  2) niri only"
  say "  3) Both (Hyprland + niri)  <- shared configs are installed either way"
  say ""
  while true; do
    printf 'Choice [1-3]: '
    read -r answer
    case "$answer" in
      1) CHOICE=hyprland; break ;;
      2) CHOICE=niri;     break ;;
      3) CHOICE=both;     break ;;
      *) warn "please enter 1, 2 or 3" ;;
    esac
  done
}

print_summary() {
  say ""
  info "Done — installed for: $CHOICE"
  say ""
  say "Next steps:"
  case "$CHOICE" in
    hyprland) say "  • Log out and pick 'Hyprland' at your display manager." ;;
    niri)     say "  • Log out and pick 'niri' at your display manager." ;;
    both)     say "  • Log out and pick 'Hyprland' or 'niri' at your display manager." ;;
  esac
  say "  • Noctalia auto-starts from the compositor config (no extra step)."
  if [ "$CHOICE" != "niri" ]; then
    say "  • Hyprland: SUPER+SHIFT+Y exits, SUPER+L locks (hyprlock)."
  fi
  if [ "$(readlink -f "$CONFIG_DIR/kitty" 2>/dev/null)" = "$REPO_DIR/shared/kitty" ]; then
    say "  • Kitty background uses ~/Pictures/dotfiles-wallpapers/kitty-wall.jpg."
  fi
  if [ -d "$BACKUP_ROOT" ]; then
    say ""
    say "Backups of replaced configs: $BACKUP_ROOT"
  fi
  if [ "$DRY_RUN" = 1 ]; then
    say ""
    warn "dry run only — nothing was actually changed"
  fi
}

main() {
  say "Noctalia + Hyprland/niri dotfiles installer"
  say "repo: $REPO_DIR"
  [ "$DRY_RUN" = 1 ] && warn "dry run — no changes will be made"

  choose_compositor

  if [ "$SKIP_DEPS" != 1 ]; then
    check_deps
  else
    say "  (dependency check skipped)"
  fi

  if [ "$DRY_RUN" != 1 ]; then
    say ""
    if ! confirm "Symlink configs into $CONFIG_DIR (existing ones get backed up)?"; then
      say "aborted — nothing changed."
      exit 0
    fi
  fi

  install_shared
  install_compositor
  seed_noctalia_settings
  print_summary
}

main "$@"

confirm() {
  [ "$ASSUME_YES" = 1 ] && return 0
  if [ ! -t 0 ]; then
    err "not running on a TTY; re-run with --yes to confirm non-interactively"
    return 1
  fi
  printf '%s [y/N] ' "$1"
  read -r reply
  case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}
