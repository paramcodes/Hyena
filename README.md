# Noctalia Rice — Hyprland + niri dotfiles

A single, installable "rice" for **two Wayland compositors — [Hyprland](https://hypr.land)
and [niri](https://github.com/YaLTeR/niri)** — sharing one shell:
**[Noctalia](https://noctalia.dev)** (bar, launcher, notifications, lock screen,
wallpaper and theming, all colour-matched to a Tokyo Night palette).

The same Noctalia bar, notification daemon, launcher, lock screen and
wallpapers work in *both* compositors, so this repo keeps one copy of everything
that is shared and only splits out the parts that are genuinely
compositor-specific.

```
dotfiles/
├── hypr/            # Hyprland-only config
│   ├── hyprland.lua     # Hyprland Lua config (binds, rules, autostart)
│   └── hyprlock.conf    # hyprlock screen locker
├── niri/            # niri-only config
│   ├── config.kdl       # niri config (binds, rules, autostart)
│   └── noctalia.kdl     # niri layout/border colours (included by config.kdl)
├── shared/          # used by BOTH compositors
│   ├── noctalia/        # Noctalia shell config + settings.toml.example
│   ├── kitty/           # terminal
│   ├── fuzzel/          # application launcher
│   ├── btop/            # system monitor
│   ├── gtk-3.0/ gtk-4.0/# GTK theming (colour-matched by Noctalia)
│   ├── qt5ct/ qt6ct/    # Qt theming
│   ├── wallpapers/      # wallpapers referenced by the configs
│   └── scripts/         # helper scripts (audio / mic switching)
├── install.sh
├── .gitignore
├── LICENSE
└── README.md
```

## Requirements

Everything below is expected to be on your `PATH`. `install.sh` checks for the
ones you select and tells you the exact `dnf`/`pacman`/`apt` line to run.

### Shared (needed for either compositor)

| Purpose | Packages |
|---|---|
| Shell / bar / notifications / lock / launcher panel | `noctalia` |
| Terminal | `kitty` (+ a monospace font; config asks for **Source Code Pro**) |
| Application launcher | `fuzzel` |
| System monitor | `btop` |
| File manager | `nautilus` |
| Media keys | `playerctl` |
| Volume keys | `wireplumber` (`wpctl`), PipeWire |
| Brightness keys | `brightnessctl` |
| Screenshots / clipboard | `grim`, `slurp`, `wl-clipboard` (`wl-copy`) |
| GTK/Qt theming | `gtk3`, `gtk4`, `qt5ct`, `qt6ct` |

### Hyprland only

| Purpose | Packages |
|---|---|
| Compositor | `hyprland` (`hyprctl`) |
| Screen locker | `hyprlock` |
| Portals | `xdg-desktop-portal`, `xdg-desktop-portal-hyprland` |
| Startup env | `dbus` (`dbus-update-activation-environment`) |

### niri only

| Purpose | Packages |
|---|---|
| Compositor | `niri` |
| Polkit agent | `xfce-polkit` (niri config starts `/usr/libexec/xfce-polkit`) |
| Screen locker (optional) | `swaylock` — niri's bind uses `noctalia msg session lock` |

> **Distro notes.**
> * **Fedora** (what this was built on): `hyprland`, `niri` and `noctalia` were
>   all installable directly (`hyprland-0.56.2`, `niri-26.04`, `noctalia-5.1.0`).
>   `noctalia` may come from a COPR on some releases.
> * **Arch**: `hyprland`, `niri`, `hyprlock`, `kitty`, `fuzzel`, `btop`,
>   `playerctl`, `brightnessctl`, `wl-clipboard`, `grim`, `slurp` are in the
>   official repos; Noctalia is in the AUR/`noctalia` package depending on your
>   setup.
> * **Debian/Ubuntu**: newer packages (`niri`, `noctalia`) usually need a
>   third-party repo or a build from source.

## Install

```bash
git clone https://github.com/<you>/<repo>.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will:

1. **Ask which compositor you want** — `1) Hyprland`, `2) niri`, or `3) both`.
   (Skip the prompt with `--hyprland`, `--niri` or `--both`.)
2. **Check dependencies** for that selection and print the install command for
   any that are missing.
3. **Back up** every existing config it is about to replace into
   `~/.dotfiles-backup/<timestamp>/`.
4. **Symlink** (never copy) `shared/` plus the chosen compositor folder(s) into
   the right places:
   * `shared/noctalia` → `~/.config/noctalia`
   * `shared/kitty`, `shared/fuzzel`, `shared/btop`, `shared/qt5ct`, `shared/qt6ct`
     → `~/.config/<name>`
   * `shared/gtk-3.0` and `shared/gtk-4.0` → files are linked *individually* into
     `~/.config/gtk-{3,4}.0/` so personal files (e.g. GTK bookmarks) survive
   * `shared/wallpapers` → `~/Pictures/dotfiles-wallpapers`
   * `shared/scripts/*.sh` → `~/.local/bin/`
   * `hypr/` → `~/.config/hypr` and/or `niri/` → `~/.config/niri`
5. **Seed Noctalia's settings** from `shared/noctalia/settings.toml.example`
   into `~/.local/state/noctalia/settings.toml` — *only if that file does not
   already exist*, so your live bar/theme settings are never clobbered.

It is safe to re-run: symlinks that already point into the repo are left alone.

**Useful flags**

```bash
./install.sh --dry-run        # show what would happen, change nothing
./install.sh --both -y        # non-interactive
./install.sh --niri --skip-deps
```

Then log out and pick **Hyprland** or **niri** in your display manager. Noctalia
starts automatically (Hyprland: `hyprland.lua` autostart; niri:
`spawn-at-startup "noctalia"`).

### Uninstall

```bash
# remove the symlinks, then restore from your backup if you want the old configs
rm ~/.config/{hypr,niri,noctalia,kitty,fuzzel,btop,qt5ct,qt6ct}
rm ~/Pictures/dotfiles-wallpapers
```

## Keybindings

`SUPER` is the main modifier in both configs (`mainMod` in Hyprland, `Mod` in
niri). `ALT` is used for the window switcher.

### Hyprland (`hypr/hyprland.lua`)

| Keybinding | Action |
|---|---|
| `SUPER + T` | Terminal (kitty) |
| `SUPER + Q` | Close window |
| `SUPER + E` | File manager (nautilus) |
| `SUPER + D` | Noctalia launcher |
| `SUPER + V` | Toggle floating |
| `SUPER + F` | Toggle maximize |
| `SUPER + SHIFT + F` | Toggle fullscreen |
| `SUPER + SHIFT + P` | Toggle pseudo-tile |
| `SUPER + J` | Toggle split (dwindle) |
| `SUPER + L` | Lock (hyprlock) |
| `SUPER + M` | Toggle microphone (`toggle-mic.sh`) |
| `SUPER + I` | Noctalia settings |
| `ALT + Tab` | Noctalia window switcher |
| `SUPER + arrows` | Move focus (left/right/up/down) |
| `SUPER + 1..0` | Focus workspace 1–10 |
| `SUPER + SHIFT + 1..0` | Move window to workspace 1–10 |
| `SUPER + S` / `SUPER + SHIFT + S` | Toggle / move to special workspace |
| `SUPER + mouse down/up` | Next / previous workspace |
| `SUPER + LMB drag` | Move window |
| `SUPER + RMB drag` | Resize window |
| `SUPER + P` | Screenshot region (Noctalia) |
| `PRINT` | Screenshot fullscreen (Noctalia) |
| `SUPER + PRINT` | Screenshot + annotate (Noctalia) |
| `SUPER + SHIFT + R` | Toggle screen recording (Noctalia plugin) |
| `SUPER + SHIFT + G` | Save replay buffer (Noctalia plugin) |
| `SUPER + SHIFT + Y` | Exit Hyprland (`hyprshutdown`, falls back to `hyprctl`) |
| `XF86Audio{Raise,Lower}Volume`, `XF86AudioMute` | Volume (`wpctl`) |
| `XF86Audio{MicMute,Play,Pause,Next,Prev}` | Media / mic (`wpctl`, `playerctl`) |
| `XF86MonBrightness{Up,Down}` | Brightness (`brightnessctl`) |

### niri (`niri/config.kdl`)

| Keybinding | Action |
|---|---|
| `SUPER + T` | Terminal (kitty) |
| `SUPER + D` | Launcher (fuzzel) |
| `SUPER + Space` | Noctalia launcher |
| `SUPER + E` | File manager (nautilus) |
| `SUPER + L` | Lock (`noctalia msg session lock`) |
| `SUPER + Q` | Close window |
| `SUPER + O` | Toggle overview |
| `SUPER + SHIFT + /` | Show hotkey overlay |
| `SUPER + Left/Down/Up/Right`, `SUPER + H/J/K/L` | Focus column / window |
| `SUPER + CTRL + arrows`, `SUPER + CTRL + H/J/K/L` | Move column / window |
| `SUPER + SHIFT + arrows`, `SUPER + SHIFT + H/J/K/L` | Focus monitor |
| `SUPER + SHIFT + CTRL + arrows/HJKL` | Move column to monitor |
| `SUPER + Page_Down/Up`, `SUPER + U/I` | Focus workspace down / up |
| `SUPER + CTRL + Page/U/I` | Move column to workspace |
| `SUPER + SHIFT + Page/U/I` | Move workspace down / up |
| `SUPER + 1..9` | Focus workspace 1–9 |
| `SUPER + CTRL + 1..9` | Move column to workspace 1–9 |
| `SUPER + F` / `SUPER + SHIFT + F` | Maximize column / fullscreen window |
| `SUPER + M` | Maximize window to edges |
| `SUPER + CTRL + F` | Expand column to available width |
| `SUPER + C` / `SUPER + CTRL + C` | Center column / center all visible columns |
| `SUPER + R` / `SUPER + SHIFT + R` | Cycle preset column width (fwd / back) |
| `SUPER + CTRL + SHIFT + R` | Cycle preset window height |
| `SUPER + CTRL + R` | Reset window height |
| `SUPER + Minus` / `SUPER + Equal` | Shrink / grow column |
| `SUPER + SHIFT + Minus/Equal` | Shrink / grow window height |
| `SUPER + V` / `SUPER + SHIFT + V` | Toggle floating / swap focus |
| `SUPER + W` | Toggle tabbed column display |
| `SUPER + [` / `SUPER + ]` | Consume / expel window left / right |
| `SUPER + ,` / `SUPER + .` | Consume into / expel from column |
| `SUPER + WheelScroll{,Up,Down,Left,Right}` | Focus / move columns & workspaces |
| `SUPER + Home/End` | Focus first / last column |
| `PRINT` / `CTRL + PRINT` / `ALT + PRINT` | Screenshot / screen / window |
| `SUPER + Escape` | Toggle keyboard-shortcut inhibitor |
| `SUPER + SHIFT + E`, `CTRL + ALT + Delete` | Quit niri |
| `SUPER + SHIFT + P` | Power off monitors |
| `XF86Audio*`, `XF86MonBrightness*`, `F11`/`F12` | Volume / media / brightness |
| `SUPER + ALT + S` | Toggle screen reader (orca) |

## Theming / Noctalia notes

* Noctalia owns the bar, notifications, launcher panel, lock screen, OSDs and
  wallpaper. It is started by the compositor, **not** by a systemd user unit.
* Noctalia's *live* settings live in `~/.local/state/noctalia/settings.toml`
  (written by its GUI). This repo ships a sanitized copy as
  `shared/noctalia/settings.toml.example`; `install.sh` only writes it if you
  don't already have a settings file.
* Palette: built-in **Tokyo Night** theme + **Oxocarbon** community palette,
  dark mode, `m3-content` wallpaper scheme. Noctalia also generates the kitty,
  fuzzel, btop, GTK3/4, Qt and niri theme files that are checked in under
  `shared/` — re-running Noctalia's wallpaper theming regenerates them in place.
* `shared/noctalia/templates.toml` enables the **built-in** templates
  (`niri`, `kitty`, `gtk3`, `gtk4`, `qt`, `btop`) and the **community**
  templates `zen-browser`, `antigravity`, `opencode`, `pi-agent`, `neovim`,
  `fuzzel`, `obs`. Community templates must be installed from Noctalia's plugin
  browser.
* `shared/noctalia/idle.toml` uses `hyprlock` as the lock command. On niri you
  probably want to change that to `noctalia msg session lock` (or `swaylock`).
* **Hardware-specific bits** (adjust or delete these):
  * `shared/scripts/toggle-mic.sh`, `audio-setup.sh`, `mic-setup.sh` hardcode
    ALSA card/PCM ids from the machine this rice came from
    (`alsa_input.pci-0000_00_1b.0`, `amixer -c 1`). `SUPER + M` in Hyprland calls
    `toggle-mic.sh`.
  * `hypr/hyprland.lua` has a stray per-device rule for `epic-mouse-v1`.
  * Noctalia's lockscreen widgets are positioned for a 1366x768 `eDP-1` output.

## Distro portability

This rice was authored on **Fedora 44** but the configs themselves are
distro-agnostic. The `install.sh` script just symlinks files — it checks for
missing dependencies per distro (`dnf` / `pacman` / `apt` / `zypper`) but works
anywhere bash ≥ 4 runs. What actually differs per distro is the availability of
the packages:

| Component | Arch | Fedora | Debian / Ubuntu | NixOS | openSUSE |
|---|---|---|---|---|---|
| **Hyprland** | `extra/hyprland` | `hyprland` | `hyprland` (testing/sid; `bookworm-backports` for 0.55) | `hyprland` in nixpkgs | X11:Wayland repo |
| **niri** | `extra/niri` | `niri` | ❌ not packaged — build from source or use a community `.deb` | `niri` in nixpkgs | X11:Wayland repo |
| **Noctalia (v5)** | `extra/noctalia` | `noctalia` (F44+; `noctalia-git` in `lionheartp/Hyprland` COPR for older) | packaged, but the version tracks upstream closely — see [docs](https://docs.noctalia.dev) | `noctalia` in nixpkgs-unstable, or the upstream flake (has home-manager / NixOS / Hjem modules + cachix binary cache) | OBS `home:neifua:Noctalia` |
| **hyprlock** | `extra/hyprlock` | `hyprlock` | `hyprlock` (testing/sid + backports) | `hyprlock` in nixpkgs | X11:Wayland repo |

Note: Noctalia **v4** (`noctalia-shell`, Quickshell-based) is no longer
maintained — on older distro repos you may still see that name; prefer v5
(package is just `noctalia`).

Other portability notes:

* **bash ≥ 4** is required by `install.sh` (`declare -A`); macOS's ancient bash
  3.2 would need Homebrew bash, but that's irrelevant on Linux.
* The niri config's polkit-agent line is now a `spawn-sh-at-startup` one-liner
  that probes the standard paths on Fedora (`/usr/libexec/xfce-polkit`), Arch
  (`/usr/lib/xfce-polkit/xfce-polkit`), and Debian/Ubuntu
  (`/usr/lib/x86_64-linux-gnu/xfce-polkit/xfce-polkit`) and falls back to
  whatever `xfce-polkit` is on `$PATH` — works on any distro with the AUR /
  Fedora / Debian `xfce-polkit` package (or `polkit-gnome` / `lxpolkit` if you
  edit that line).
* `shared/gtk-3.0/settings.ini` ships with the KDE-only
  `colorreload-gtk-module` / `window-decorations-gtk-module` line commented out
  — those modules only exist inside a full KDE Plasma install and just produce
  GTK warnings elsewhere. Re-enable only if you also run Plasma.
* kitty.conf likewise references the two Breeze GTK modules and the `breeze`
  icon/cursor theme — harmless without them, but install `breeze-icons` for the
  intended look.
* **NixOS caveat:** `install.sh` symlinks into `$HOME/.config`, which works, but
  the idiomatic NixOS approach is to consume these files via
  `home-manager` / Hjem. Noctalia upstream ships `homeModule` /
  `nixosModule` / `hjemModules.default` with a `programs.noctalia.enable`
  option, plus a [cachix](https://noctalia.cachix.org) binary cache, so you'd
  typically wrap this repo's files in your own Nix expressions rather than run
  `install.sh`. See [docs.noctalia.dev → NixOS](https://docs.noctalia.dev/noctalia/getting-started/nixos/).
* Debian 12 "bookworm" ships GCC 12; building Noctalia from source there
  requires `g++-13` (`CXX=g++-13`). On Debian/Ubuntu prefer the packaged
  version over a source build.



## Credits

* **Hyprland** config is based on Hyprland's own example config
  ([wiki.hypr.land](https://wiki.hypr.land/Configuring/Start/)) — the new Lua
  config format.
* **niri** config is based on niri's default example config
  ([niri-wm.github.io](https://niri-wm.github.io/niri/Configuration:-Introduction)).
* **Tokyo Night** palette by **Folke Lemaitre** (MIT) —
  [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim); the kitty
  colours derive from `extras/kitty/tokyonight_night.conf`.
* **Oxocarbon** community palette, used by Noctalia's theme engine.
* **Noctalia** shell and its generated theme templates —
  [noctalia.dev](https://noctalia.dev).
* GTK window-decoration assets under `shared/gtk-3.0/assets/` are from the
  GTK/Breeze-style decoration set.

## License

[MIT](LICENSE) — note that the upstream configs/palettes credited above carry
their own licenses.