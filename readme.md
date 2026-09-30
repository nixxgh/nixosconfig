# ❄️ Declarative Multi-Tenant Workstation Fleet

> An enterprise-grade, NixOS-based infrastructure-as-code platform supporting multi-user, multi-device deployments with blast-radius-controlled rebuild pipelines, unprivileged user-space management, and zero-touch onboarding via fleet templates. Built on **Niri** (scrollable tiling Wayland compositor), tracking `nixos-unstable`.

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![flake-parts](https://img.shields.io/badge/framework-flake--parts-orange.svg)](https://github.com/hercules-ci/flake-parts)
[![Dendritic Architecture](https://img.shields.io/badge/pattern-dendritic%20autoloader-emerald.svg)](https://github.com/vic/import-tree)

---

> [!NOTE]
> ### 🌟 Looking to Build Your Own Fleet? Start Here:
> **This repository is the author's active daily-driver workstation (`laptop`) and serves as the live, battle-tested reference implementation.** It contains personalized dotfiles (Niri, Neovim, Tmux, AGS bar), application suites, and physical hardware configs.
>
> - 🚀 **Recommended Starting Point**: If you are building your own fleet or looking for a clean, zero-bloat foundation, please use the official starter framework: **[`nixxgh/nixos-enterprise-fleet`](https://github.com/nixxgh/nixos-enterprise-fleet)**. It provides the pure turnkey scaffolding with zero personal data or technical debt to clean up.
> - 💻 **Using This Daily-Driver Setup**: You are fully welcome to clone, adapt, or study this configuration directly if you wish to replicate this exact Niri + Neovim + AGS environment, provided you abide by the **[CC BY-NC-SA 4.0 License](LICENSE)** (strictly non-commercial use, prominent attribution to `nixx`, and share-alike terms).

---

## 🏛️ Architectural Philosophy: The Fleet Model

Most NixOS repositories suffer from **configuration leakage**: machines are tangled with specific user accounts, and home-manager configurations are hardcoded to physical chassis.

This platform completely decouples **Hardware**, **Host Policy**, and **User Identity** into three autonomous layers:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HOST DOMAIN CAPSULE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   host/environment/   ──► Shared workstation profile, daemons (audio,       │
│                           sddm, tailscale, ssh), programs (niri), sudo.    │
│                                                                             │
│   host/users/         ──► Unprivileged user capsules (dotfiles, ZSH,        │
│                           neovim, tmux, packages). Roam across all devices. │
│                                                                             │
│   host/machines/      ──► Silicon & hardware scans only (partitions,        │
│                           CPU microcode, laptop quirks). Zero user logic.   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Hardware as a Commodity**: A physical machine is just a block-storage scan. Adding a laptop or desktop takes 2 minutes by dropping a hardware scan into `modules/host/machines/<name>/`.
2. **True Persona Roaming**: Any team member defined under `host/users/` exists on every machine in the fleet. Any member can log into any workstation and immediately receive their identical shell, apps, and dotfiles.
3. **Blast-Radius Isolation**: Modifying a personal shell config never risks breaking the system kernel or display manager, and system-level daemon updates never reset or interrupt user sessions.

---

## 🏷️ The Golden Naming Convention & Machine Customization

A core design superpower of this platform is **zero-touch dynamic binding** driven by directory names:

```text
modules/host/machines/<machine-name>/
├── <machine-name>-configuration.nix          <── Chassis Customization & Quirks Layer
└── <machine-name>-hardware-configuration.nix  <── Physical Storage & Silicon Scan
```

### 1. The Directory-Driven Contract (`baseNameOf ./.`)
Every machine profile evaluates its identity dynamically:
```nix
hostName = baseNameOf ./.;
```
Whatever you name the machine's directory (e.g. `laptop`, `desktop`, `workstation`) automatically binds to:
1. `self.nixosModules."${hostName}Hardware"` (matching `<machine>-hardware-configuration.nix`)
2. `networking.hostName = hostName;`
3. Flake output target `#<machine>` (for `forcerebuildall`)
4. Flake output target `#<machine>-env` (for `rebuildenvironment`)

> **⚠️ Strict Rule**: If your directory is `.../machines/desktop/`, your two files **MUST** be named exactly:
> - `desktop-configuration.nix`
> - `desktop-hardware-configuration.nix`

---

### 2. Why `<machine>-configuration.nix` Matters (The Chassis Override Layer)
While `environment.nix` enforces uniform shared baseline rules across **all machines** (core daemons, audio, display manager, rebuild aliases), `<machine>-configuration.nix` gives you an isolated **Chassis Override Layer**:

- **Laptop Chassis** (e.g. `laptop-configuration.nix`):
  Enables touchpad tapping and lid-switch lock behavior (`HandleLidSwitch = "lock"`).
- **Dedicated GPU Workstation** (e.g. `desktop-configuration.nix`):
  Enables proprietary Nvidia drivers, multi-monitor display arrangements, and high-performance fan curves.
- **Headless Servers / Builders**:
  Disables display managers (`services.displayManager.sddm.enable = false;`) or mounts custom ZFS storage pools.

**Result**: You can customize every physical chassis to its silicon without polluting or altering the shared environment configuration!

---

### 3. The User Capsule Contract (`<username>-configuration.nix`)
Just like machines, team members use the exact same directory-driven dynamic contract:

```text
modules/host/users/<username>/
├── <username>-configuration.nix             <── User Capsule (Identity & Shell Aliases)
├── packages.nix                             <── Personal Userland Packages
├── programs/                                <── Modular Dotfiles (git, neovim, zsh, etc.)
└── services/                                <── User background daemons
```

Inside `<username>-configuration.nix`:
```nix
userName = baseNameOf ./.;
```
Whatever you name the user's folder (e.g. `alice`, `bob`, `nixx`) automatically binds to:
1. `flake.homeModules.${userName}` (exported for system integration)
2. `flake.homeConfigurations.${userName}` (unprivileged standalone rebuild target `#<username>`)
3. `home.username = userName;` & `home.homeDirectory = "/home/${userName}";`

> **⚠️ Strict Rule**: If your directory is `.../users/alice/`, your main user file **MUST** be named `alice-configuration.nix`.

---

### 4. Automatic Fleet Roaming: How Home Manager Applies Users
**Do you have to edit machine files to add a user? NO.**

Because every physical machine imports `self.nixosModules.commonHost`, any user declared in `modules/host/environment/users.nix` **automatically applies to every machine in the fleet**:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HOW USERS ROAM ACROSS ALL MACHINES                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: Copy Template Capsule                                             │
│   users/_template/ ──► users/alice/alice-configuration.nix                  │
│                        (Automatically exports self.homeModules.alice)       │
│                                                                             │
│                                      │                                      │
│                                      ▼                                      │
│                                                                             │
│   Step 2: Wire into Host Blueprint (Single Point of Registration)           │
│   In modules/host/environment/users.nix:                                    │
│     users.users.alice = { isNormalUser = true; ... };                       │
│     home-manager.users.alice = self.homeModules.alice;                      │
│                                                                             │
│                                      │                                      │
│                                      ▼                                      │
│                                                                             │
│   Step 3: Zero-Touch Cascading to ALL Fleet Devices                         │
│   ├── machines/laptop/    ──► Imports commonHost ──► Alice is provisioned!  │
│   ├── machines/desktop/   ──► Imports commonHost ──► Alice is provisioned!  │
│   └── machines/server/    ──► Imports commonHost ──► Alice is provisioned!  │
│                                                                             │
│   Result: Alice's account, Home Manager dotfiles, and packages exist on     │
│   every physical computer in the fleet without touching any machine file.   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 5. Centralized Root Governance & Privilege Delegation

All root authority is strictly centralized in [`users.nix`](modules/host/environment/users.nix). Individual user capsules (`modules/host/users/<username>/`) are completely unprivileged Home Manager modules and **cannot** elevate their own permissions or declare system services.

```text
┌────────────────────────────────────────────────────────────────────────┐
│             CENTRALIZED ROOT CONTROL & PRIVILEGE BOUNDARY              │
├────────────────────────────────────────────────────────────────────────┤
│  modules/host/environment/users.nix                                    │
│  [THE SOVEREIGN ROOT CONTROLLER - MANAGED BY FLEET ADMINISTRATORS]     │
│                                                                        │
│  • nix.settings.trusted-users = [ "root" "@wheel" ];                   │
│  • Centralized user accounts, privilege delegation, & Home Manager     │
├───────────────────────────────────┬────────────────────────────────────┤
│    ADMINISTRATOR / FLEET LEAD     │     STANDARD / RESTRICTED USER     │
├───────────────────────────────────┼────────────────────────────────────┤
│  users.users.alice = {            │  users.users.bob = {               │
│    isNormalUser = true;           │    isNormalUser = true;            │
│    extraGroups = [                │    extraGroups = [                 │
│      "wheel"          <── SUDO   │      "networkmanager"              │
│      "networkmanager"             │      # NO WHEEL! (Zero sudo access)│
│    ];                             │    ];                              │
│  };                               │  };                                │
├───────────────────────────────────┼────────────────────────────────────┤
│  • Full sudo root execution       │  • NO sudo / root execution        │
│  • Can run forcerebuildall        │  • CANNOT run nixos-rebuild        │
│  • Trusted Nix daemon operator    │  • CAN ONLY run rebuildhome        │
│  • Manages fleet machines & OS    │  • Sandboxed to personal $HOME     │
└───────────────────────────────────┴────────────────────────────────────┘
```

#### Provisioning an Administrator (`wheel` + `trusted-users`)
To grant an engineer full administrative access:
```nix
users.users.adminUser = {
  isNormalUser = true;
  shell = pkgs.zsh;
  extraGroups = [
    "wheel"          # Grants sudo root access
    "networkmanager" # Network configuration
    "docker"         # Docker daemon access
    "input"          # Direct hardware input
    "uinput"         # Virtual controller / input emulation
  ];
};
```
Because `environment.nix` specifies `nix.settings.trusted-users = [ "root" "@wheel" ]`, membership in `"wheel"` automatically grants communication with the Nix daemon, remote binary cache substitution, and execution of system-wide rebuild pipelines (`forcerebuildall`, `rebuildenvironment`).

#### Provisioning a Restricted / Standard User
To give a developer or contractor a full development environment across the entire fleet without root permissions:
```nix
users.users.devUser = {
  isNormalUser = true;
  shell = pkgs.zsh;
  extraGroups = [
    "networkmanager" # WiFi & network configuration only
  ];
};
```
Restricted users cannot modify system configuration, cannot alter hardware settings, and cannot access other users' data. They customize their tools and dotfiles purely via unprivileged Home Manager rebuilds (`rebuildhome`).

---

## 🔄 Rebuild & Blast-Radius Control Matrix

Instead of a single monolithic rebuild command, this platform exposes three dedicated pipelines matching administrative blast radiuses:

```text
┌─────────────────────────┬───────────────────────────────┬─────────────────────────┐
│ Target & Command        │ Scope & Impact                │ Privilege Level         │
├─────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ forcerebuildall /       │ Full cascading cycle:         │ Requires sudo           │
│ forceupdateall /        │ Applies system + all users,   │ (Root administrator)    │
│ forcecleanall           │ updates lock, or sweeps all   │                         │
├─────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ rebuildenvironment /    │ Non-cascading OS cycle:       │ Requires sudo           │
│ updateenvironment /     │ Updates/cleans kernel/daemons │ (Leaves users untouched)│
│ cleanenvironment        │ only (strips user space)      │                         │
├─────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ rebuildhome /           │ Standalone user generation:   │ 100% Unprivileged       │
│ updatehome /            │ Updates/cleans dotfiles & HM  │ (Zero root / no sudo)   │
│ cleanhome               │ packages in user space        │                         │
└─────────────────────────┴───────────────────────────────┴─────────────────────────┘
```

### 1. Core Architecture Pipelines (The Reusable Framework)

Every machine and user instantiated from the templates inherits these immutable rebuild and maintenance pipelines:

| Command              | Target                  | Scope & Cascading Status                                                                 | Permission Level       |
| :------------------- | :---------------------- | :--------------------------------------------------------------------------------------- | :--------------------- |
| `forcerebuildall`    | `#${hostName}`          | Full atomic rebuild (**cascading** into all wired user home-manager profiles)            | Requires `sudo`        |
| `forceupdateall`     | `#${hostName}`          | Updates `flake.lock` and executes full cascading rebuild across machine and all users    | Requires `sudo`        |
| `forcecleanall`      | Both User & System      | Purges old HM & system generations, sweeps all garbage, and runs `nix store optimise`   | Requires `sudo`        |
| `rebuildenvironment` | `#${hostName}-env`      | Rebuilds system environment only (**non-cascading**; strips user space via `mkForce {}`) | Requires `sudo`        |
| `updateenvironment`  | `#${hostName}-env`      | Updates `flake.lock` and applies system-only rebuild                                     | Requires `sudo`        |
| `cleanenvironment`   | `#${hostName}-env`      | Purges old system generations, sweeps system garbage, and optimizes store                | Requires `sudo`        |
| `rebuildhome`        | `#${userName}`          | Rebuilds user space only (`home-manager switch --flake .#<user>`)                       | **100% Unprivileged**  |
| `updatehome`         | `#${userName}`          | Updates `flake.lock` and rebuilds user space only                                       | **100% Unprivileged**  |
| `cleanhome`          | `#${userName}`          | Purges old user & Home Manager generations, collects user garbage (zero sudo required)  | **100% Unprivileged**  |

---

### 2. Workstation & Tooling Shortcuts (The Reference Implementation)

These are environment utilities wired for machine `laptop` and user `nixx`:

| Command     | Tool / Component       | Description                                                                              |
| :---------- | :--------------------- | :--------------------------------------------------------------------------------------- |
| `ff`        | Fastfetch              | Displays Fastfetch system and hardware identity banner                                   |
| `autologin` | OpenSSH / SDDM / Niri  | Headless remote unlock script via SSH to initialize and unlock physical graphical session|
| `agui`      | Antigravity IDE        | Launches Antigravity AI-first development environment                                    |

---

## 🚀 System Capabilities & Features

### 1. Autonomous & Unattended Remote Operation
- **Wake-on-LAN (WoL)**: Multi-layer declarative WoL configuration on wired ethernet (`eno1`) utilizing `networking.interfaces.eno1.wakeOnLan`, NetworkManager connection profiles, udev rules, and a boot-time oneshot systemd service to ensure WoL is always re-armed.
- **Encrypted Mesh Networking**: Native **Tailscale** mesh VPN (`useRoutingFeatures = "client"`) for zero-config, firewall-traversing remote access from anywhere. The Tailscale interface is trusted by the system firewall.
- **Remote Desktop & Game Streaming**: **Sunshine** host server (`autoStart = true`, `capSysAdmin = true` for DRM/KMS Wayland capture) paired with **Moonlight** clients for ultra-low latency desktop streaming over Tailscale.
- **Remote Headless Login**: SSH-based `autologin` script with passwordless sudo permissions to cleanly authenticate SDDM, initialize Niri, and unlock the physical session remotely. Supports `status`, `login`, `logout`, and `toggle` subcommands.

### 2. Wayland Desktop (Niri)
- **Niri Compositor**: Modern scrollable tiling Wayland compositor configured declaratively via `nix-wrapper-modules`. Built from a custom wrapped package (`packages.myNiri`) with all settings, binds, and extras configured in Nix.
- **XWayland Support**: `xwayland-satellite` integrated for compatibility with legacy X11 applications.
- **Vim-Centric Navigation**: `Mod + HJKL` for column/window focus, `Mod + Ctrl + HJKL` for moving columns/windows, `Mod + U/I` for workspace navigation.
- **Subtle Aesthetics**: Dark `#000000` canvas background with minimal focus rings (active: `#5a5a5a`, inactive: `#242424`), 5px gaps, and a 4-pass blur effect.
- **SDDM Display Manager**: Clean Wayland greeter.
- **Screen Lock**: **Hyprlock** as the session locker with a blurred screenshot background, clock/date overlay, and a styled password input field.
- **Idle Management**: **Hypridle** automatically turns off monitors after 60s when locked, auto-locks after 3 minutes of inactivity, and powers off monitors at 4 minutes.

### 3. Status Bar & Notifications
- **AGS / Astal Bar**: Custom status bar built with [AGS](https://github.com/aylur/ags) (Astal framework), compiled at build time with Tailwind CSS. Features battery, network, Bluetooth, WirePlumber audio, MPRIS media, notification indicator, system tray, and power profiles via dedicated Astal library modules.
- **Waybar**: Secondary Waybar config available (bottom bar) showing Niri workspaces, window title, volume, battery, night light toggle, caffeine toggle, notification bell, system tray, and a live clock.

### 4. Developer & Terminal Environment
- **Shell**: **ZSH** with Starship prompt (minimal `directory + git_branch + git_status` format), syntax highlighting, autosuggestions, and a 10,000-line shared history.
- **Terminal**: **Alacritty** (GPU-accelerated) bound to `Mod + T`, styled with JetBrainsMono Nerd Font.
- **Multiplexer**: **Tmux** with full 24-bit TrueColor (`RGB`), Vim navigation, and mouse support.
- **File Management**: **Yazi** terminal file manager with rich file previews and shell integrations.
- **Fuzzy Finder**: **FZF** for shell integration and **Fuzzel** as the Wayland app launcher (bound to `Mod + D`).
- **Shell History**: **Atuin** for encrypted, searchable shell history.
- **System Monitor**: **Btop** for real-time resource monitoring.
- **Quick Docs**: **Tealdeer** (fast `tldr` client) for offline command cheat sheets.
- **Browsers**: **Zen Browser** (tracked via `zen-browser-flake`) and **Firefox**.
- **Containers & Dev Tools**: **Docker** daemon enabled at root, `yt-dlp`, and clipboard-integrated Neovim.
- **Antigravity IDE**: `antigravity-ide` package installed with `agui` alias for quick launch.

### 5. Display & Ambiance
- **Night Light**: **wlsunset** for automatic color temperature shifting (6500K day → 4000K night), with a "forced warm" mode locked at 4000K and a Waybar toggle widget (Auto / On / Off).
- **Wallpaper**: **swaybg** set to solid `#000000` black, spawned directly by Niri at startup.
- **Blueman Applet**: System tray Bluetooth manager.
- **Network Manager Applet**: `nm-applet` for system tray WiFi/VPN management.

### 6. Neovim Configuration
- **Theme**: Catppuccin Mocha via `catppuccin-nvim`, Lualine statusline.
- **Plugins**: Treesitter (all grammars), Telescope, Harpoon2, Conform (formatting), nvim-lspconfig, vim-tmux-navigator, nvim-web-devicons.
- **LSP**: Native Neovim 0.11+ LSP (`vim.lsp.enable`) with `nixd`, `astro`, `ts_ls`, `tailwindcss`.
- **Formatters**: `nixfmt` for Nix, `prettier` for JS/TS/Astro/CSS/HTML/JSON/Markdown (format-on-save).
- **System Clipboard**: `vim.opt.clipboard = "unnamedplus"` for seamless Wayland clipboard integration via `wl-clipboard`.

### 7. Self-Healing & Maintenance
- **Automated Garbage Collection**: Weekly pruning of generations older than 7 days (`nix.gc`).
- **Store Optimization**: Automated hard-linking and deduplication of identical store paths (`nix.settings.auto-optimise-store`).
- **Polkit**: Passwordless reboot/poweroff for `wheel` group members (for remote SSH administration via Termius).

---

## 📂 Repository Architecture

The repository is organized using the **Dendritic Pattern** (`flake-parts` + `import-tree`). `import-tree` crawls `./modules` and auto-loads every `.nix` file, eliminating manual `imports = []` boilerplate at the flake level.

```text
myNixOS/
├── flake.nix                               # Entry point: inputs & flake-parts + import-tree loader
├── flake.lock                              # Pinned input revisions
├── LICENSE                                 # CC BY-NC-SA 4.0
├── readme.md                               # This file
│
└── modules/
    ├── parts.nix                           # flake-parts assembly: systems & homeModules/homeConfigurations options
    │
    └── host/                               # ── ALL HOST & USER CONFIGURATION ──
        │
        ├── environment/                    # ── SHARED HOST BASELINE (applied to every machine) ──
        │   ├── environment.nix             # commonHost module: boot, networking, locale (en_IN),
        │   │                              #   fonts (JetBrainsMono Nerd Font), Docker, Nix settings,
        │   │                              #   weekly GC, shell aliases (rebuild pipelines + ff)
        │   ├── packages.nix               # System-wide packages module (environmentPackages)
        │   ├── users.nix                  # Fleet user registry & access control (fleetUsers module)
        │   │
        │   ├── programs/
        │   │   └── niri.nix               # Niri compositor: custom wrapped package (packages.myNiri),
        │   │                              #   full keybinds, layout (gaps=5, blur passes=4),
        │   │                              #   XWayland-satellite, us+ua keyboard, touchpad tap
        │   │
        │   └── services/
        │       ├── audio.nix              # PipeWire & WirePlumber audio stack
        │       ├── bluetooth.nix          # Bluetooth daemon & power defaults
        │       ├── home-manager.nix       # Home Manager NixOS integration
        │       ├── sddm.nix               # SDDM display manager
        │       ├── security.nix           # Security hardening
        │       ├── ssh.nix                # OpenSSH server + autologin script (toggle/login/logout/status)
        │       │                          #   + passwordless sudo rules for wheel group
        │       ├── sunshine.nix           # Sunshine remote desktop streaming (DRM/KMS capture)
        │       ├── tailscale.nix          # Tailscale mesh VPN (client mode, trusted interface)
        │       └── wakeonlan.nix          # Multi-layer WoL on eno1: systemd.link, NM, udev, oneshot service
        │
        ├── machines/                       # ── PHYSICAL DEVICES (hardware & chassis quirks) ──
        │   ├── _template/                  # Turnkey machine onboarding scaffold
        │   │   ├── template-configuration.nix
        │   │   └── template-hardware-configuration.nix
        │   │
        │   └── laptop/                     # Active machine profile (#laptop / #laptop-env)
        │       ├── laptop-configuration.nix         # hostName binding, touchpad tap, lid-switch lock
        │       └── laptop-hardware-configuration.nix # Disk UUIDs, filesystems, kernel modules
        │
        └── users/                          # ── USER CAPSULES (Home Manager, unprivileged) ──
            ├── _template/                  # Turnkey user onboarding scaffold
            │   ├── template-configuration.nix
            │   ├── packages.nix
            │   ├── programs/
            │   └── services/
            │
            └── nixx/                       # Active user capsule: nixx
                ├── nixx-configuration.nix  # userName binding, all HM module imports,
                │                          #   rebuildhome / updatehome / cleanhome aliases
                ├── packages.nix            # User packages: yt-dlp, antigravity-cli, grim, slurp,
                │                          #   satty, wl-clipboard, libnotify, pavucontrol
                │
                ├── programs/
                │   ├── alacritty.nix       # Alacritty GPU-accelerated terminal (Mod+T)
                │   ├── antigravity.nix     # Antigravity IDE package + agui alias
                │   ├── astal/              # AGS/Astal status bar (TypeScript + Tailwind CSS)
                │   │   ├── astal.nix       # Nix module: Tailwind compile, AGS systemd service,
                │   │   │                  #   Astal4 + battery/wireplumber/network/bluetooth/
                │   │   │                  #   notifd/apps/mpris/tray/powerprofiles modules
                │   │   ├── app.ts          # Bar entry point
                │   │   ├── src/            # Bar widget source & style.css
                │   │   ├── tailwind.config.cjs
                │   │   └── tsconfig.json
                │   ├── atuin.nix           # Atuin encrypted shell history sync
                │   ├── btop.nix            # Btop resource monitor
                │   ├── direnv.nix          # Direnv shell environment switcher
                │   ├── fastfetch.nix       # System info banner (ff alias)
                │   ├── firefox.nix         # Firefox web browser
                │   ├── fuzzel.nix          # Fuzzel Wayland app launcher (Mod+D)
                │   ├── fzf.nix             # FZF fuzzy finder shell integration
                │   ├── git.nix             # Git identity & global config
                │   ├── hyprlock.nix        # Hyprlock screen locker:
                │   │                      #   blurred screenshot BG, clock (64px), date, password field
                │   ├── neovim.nix          # Neovim: Catppuccin-Mocha, Treesitter, Telescope,
                │   │                      #   Harpoon2, Conform, LSP (nixd/astro/ts_ls/tailwindcss)
                │   ├── swaybg.nix          # Swaybg solid-black wallpaper (#000000)
                │   ├── tealdeer.nix        # Tealdeer (tldr) offline docs
                │   ├── tmux.nix            # Tmux multiplexer (TrueColor RGB, Vim nav, mouse)
                │   ├── yazi.nix            # Yazi terminal file manager with previews
                │   ├── zen.nix             # Zen Browser (via zen-browser-flake input)
                │   └── zsh.nix             # ZSH + Starship (dir/git/status format),
                │                          #   syntax-highlighting, autosuggestions, 10k history
                │
                └── services/
                    ├── blueman-applet.nix  # Blueman system tray Bluetooth manager
                    ├── hypridle.nix        # Hypridle idle manager:
                    │                      #   DPMS off after 60s (locked), auto-lock at 3m, DPMS at 4m
                    ├── nm-applet.nix       # NetworkManager system tray applet
                    └── wlsunset.nix        # Wlsunset night light (6500K↔4000K + forced-warm 4000K mode)
```

---

## 🧭 The 2-Tier Onboarding Protocol

> **Rule of Thumb**: Always base new deployments on the unopinionated `_template` blueprints rather than copying live machine profiles. The templates feature dynamic binding (`baseNameOf ./.`), clean defaults, and zero personal credentials.

### Tier 1: Onboarding a New Machine
To add another physical laptop or workstation (e.g. `desktop`):

```bash
# 1. Create the new machine directory
mkdir -p modules/host/machines/desktop

# 2. Copy the machine templates
cp modules/host/machines/_template/template-configuration.nix modules/host/machines/desktop/desktop-configuration.nix
cp modules/host/machines/_template/template-hardware-configuration.nix modules/host/machines/desktop/desktop-hardware-configuration.nix

# 3. Populate hardware scan into desktop-hardware-configuration.nix:
# Run: nixos-generate-config --show-hardware-config
# Copy the generated filesystem, kernel modules, and root LUKS lines into the module body.

# 4. Dry-build to verify syntax and hardware bindings
nix build .#nixosConfigurations.desktop.config.system.build.toplevel --no-link

# 5. Apply the switch
sudo nixos-rebuild switch --flake .#desktop
```
*(Because `desktop-configuration.nix` uses `hostName = baseNameOf ./.`, it automatically provisions all fleet users and exports `#desktop` and `#desktop-env` without manual editing.)*

---

### Tier 2: Onboarding a New Team Member / User
To add a new user (e.g. `alice`) to the fleet:

```bash
# 1. Copy the user template capsule
cp -r modules/host/users/_template modules/host/users/alice

# 2. Rename the configuration file
mv modules/host/users/alice/template-configuration.nix modules/host/users/alice/alice-configuration.nix

# 3. Set personal Git identity in:
# nano modules/host/users/alice/programs/git.nix

# 4. In modules/host/environment/users.nix, register alice and assign permissions:
# users.users.alice = { isNormalUser = true; description = "alice"; shell = pkgs.zsh; extraGroups = [ "networkmanager" ]; };
# home-manager.users.alice = self.homeModules.alice;

# 5. Rebuild:
forcerebuildall
```
*(Alice now exists across every physical device in the fleet and can independently rebuild her dotfiles anytime using `rebuildhome`.)*

---

## ⌨️ Application Keybindings Cheatsheet

### 1. Neovim (`nvim`)
- **Leader Key**: `<Space>`

| Keybinding                | Mode           | Action           | Description                                                        |
| :------------------------ | :------------- | :--------------- | :----------------------------------------------------------------- |
| `<leader>cf`              | Normal, Visual | Format Code      | Formats buffer using `conform.nvim` (`nixfmt`, `prettier`)         |
| `<leader>ff`              | Normal         | Find Files       | Telescope fuzzy file finder                                        |
| `<leader>fg`              | Normal         | Live Grep        | Telescope ripgrep search across workspace                          |
| `<leader>fb`              | Normal         | Buffers          | Telescope open buffer list                                         |
| `K`                       | Normal         | LSP Hover        | Displays type definitions and docs in popup                        |
| `gd`                      | Normal         | Go to Definition | Jumps to source definition of symbol                               |
| `gr`                      | Normal         | Go to References | Lists all symbol references across workspace                       |
| `<leader>rn`              | Normal         | Rename Symbol    | Workspace-wide symbol rename via LSP                               |
| `<leader>ca`              | Normal         | Code Action      | LSP code action at cursor                                          |
| `<leader>d`               | Normal         | Line Diagnostics | Opens floating diagnostic window                                   |
| `[d` / `]d`               | Normal         | Prev/Next Diag   | Navigate between diagnostics                                       |
| `Ctrl + h/j/k/l`          | Normal         | Pane Navigation  | Seamless navigation between Neovim splits and Tmux panes           |
| `<leader>a`               | Normal         | Harpoon Add      | Pin current file into Harpoon                                      |
| `<leader>h` / `<C-e>`     | Normal         | Harpoon Menu     | Toggle Harpoon quick menu list                                     |
| `<leader>1` - `<leader>4` | Normal         | Harpoon Jump     | Jump directly to pinned file 1–4                                   |

### 2. Niri (Wayland Compositor)
- **Modifier Key (`Mod`)**: `Super` (Windows key)

| Keybinding                          | Action                | Description                                                   |
| :---------------------------------- | :-------------------- | :------------------------------------------------------------ |
| `Mod + T`                           | Terminal              | Opens GPU-accelerated **Alacritty** terminal                  |
| `Mod + D`                           | App Launcher          | Opens **Fuzzel** application launcher                         |
| `Super + Alt + L`                   | Lock Screen           | Locks screen with **swaylock**                                |
| `Print`                             | Screenshot            | Native Niri screenshot (saved to ~/Pictures)                  |
| `Ctrl + Print`                      | Screenshot Screen     | Full-screen native screenshot                                 |
| `Alt + Print`                       | Screenshot Window     | Focused-window native screenshot                              |
| `Mod + Q`                           | Close Window          | Closes the currently focused window                           |
| `Mod + Shift + E`                   | Quit Niri             | Exits the compositor session back to SDDM                     |
| `Ctrl + Alt + Delete`               | Quit Niri             | Alternative compositor quit                                   |
| `Mod + Shift + /`                   | Hotkey Help           | Toggles Niri's interactive hotkey overlay                     |
| `Mod + O`                           | Workspace Overview    | Toggles bird's-eye workspace overview                         |
| `Mod + H / L`                       | Focus Column L/R      | Moves focus to the adjacent column                            |
| `Mod + J / K`                       | Focus Window Down/Up  | Moves focus between windows in a column                       |
| `Mod + Ctrl + H / L`                | Move Column L/R       | Shifts active column left / right                             |
| `Mod + Ctrl + J / K`                | Move Window Down/Up   | Moves window within the current column                        |
| `Mod + U / I`                       | Focus Workspace Dn/Up | Moves focus to workspace below / above                        |
| `Mod + Ctrl + U / I`                | Move to Workspace     | Moves column to workspace below / above                       |
| `Mod + 1-9`                         | Switch Workspace      | Jump directly to workspace 1–9                                |
| `Mod + Ctrl + 1-9`                  | Move to Workspace     | Move active column to workspace 1–9                           |
| `Mod + Shift + H/J/K/L`             | Focus Monitor         | Move focus to another monitor                                 |
| `Mod + Shift + Ctrl + H/J/K/L`      | Move to Monitor       | Move column to another monitor                                |
| `Mod + Home / End`                  | Focus First/Last Col  | Jump focus to first or last column                            |
| `Mod + Ctrl + Home / End`           | Move Col First/Last   | Move active column to first or last position                  |
| `Mod + F`                           | Maximize Column       | Toggles column maximization                                   |
| `Mod + Shift + F`                   | Fullscreen Window     | Toggles window fullscreen                                     |
| `Mod + M`                           | Maximize to Edges     | Maximizes window to all edges                                 |
| `Mod + Ctrl + F`                    | Expand Column Width   | Expands column to all available width                         |
| `Mod + R`                           | Cycle Column Width    | Cycles through configured column preset widths                |
| `Mod + Shift + R`                   | Cycle Width Back      | Cycles column preset widths in reverse                        |
| `Mod + C`                           | Center Column         | Centers the active column in view                             |
| `Mod + Ctrl + C`                    | Center Visible Cols   | Centers all visible columns                                   |
| `Mod + , / .`                       | Consume / Expel       | Pulls/pushes adjacent window into/out of current column       |
| `Mod + [ / ]`                       | Consume/Expel L/R     | Consumes or expels window left or right                       |
| `Mod + V`                           | Float Toggle          | Toggles window between floating and tiling                    |
| `Mod + Shift + V`                   | Switch Float/Tile     | Switches focus between floating and tiling layers             |
| `Mod + W`                           | Tabbed Column         | Toggles tabbed display for the current column                 |
| `Mod + Minus / Equal`               | Column Width ±10%     | Fine-tunes current column width                               |
| `Mod + Shift + Minus / Equal`       | Window Height ±10%    | Fine-tunes current window height                              |
| `Mod + Shift + P`                   | Power Off Monitors    | Turns off all monitors (DPMS)                                 |
| `Mod + Escape`                      | Inhibit Shortcuts     | Toggles keyboard shortcuts inhibitor (for VMs, games, etc.)   |
| `XF86AudioRaiseVolume / Lower`      | Volume ±10%           | Adjusts master volume via WirePlumber (`wpctl`), max 100%     |
| `XF86AudioMute`                     | Mute Audio            | Toggles audio sink mute                                       |
| `XF86AudioMicMute`                  | Mute Microphone       | Toggles audio source (mic) mute                               |
| `XF86AudioPlay / Pause`             | Play/Pause Media      | Toggle media playback via `playerctl`                         |
| `XF86AudioStop`                     | Stop Media            | Stops media playback via `playerctl`                          |
| `XF86AudioPrev / Next`              | Prev/Next Track       | Skip tracks via `playerctl`                                   |
| `XF86MonBrightnessUp / Down`        | Brightness ±10%       | Adjusts screen backlight via `brightnessctl`                  |

---

## 🌟 Acknowledgements & Upstream Credits

This architecture stands on the shoulders of giants. Building this declarative, multi-tenant workstation fleet would not have been possible without the following foundational open-source technologies and their creators:

1. **[NixOS & Nixpkgs](https://github.com/NixOS/nixpkgs)** (by _Eelco Dolstra and the Nix community_) — For the pure functional package manager and declarative operating system core.
2. **[Home Manager](https://github.com/nix-community/home-manager)** (by _Robert Helgesson and the nix-community_) — For declarative, unprivileged user-space environment management.
3. **[flake-parts](https://github.com/hercules-ci/flake-parts)** (by _Hercules CI & Robert Hensing_) — For the modular flake framework enabling clean separation of concerns.
4. **[nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)** (by _BirdeeHub_) — For declarative, robust application wrapper configurations (used for the Niri package).
5. **[import-tree](https://github.com/vic/import-tree)** (by _Victor Borja_) — For the zero-boilerplate filesystem crawler that dynamically discovers and auto-loads all host modules.
6. **[AGS / Astal](https://github.com/aylur/ags)** (by _Aylur_) — For the GTK4 widget system powering the custom status bar.
7. **[zen-browser-flake](https://github.com/0xc000022070/zen-browser-flake)** — For the Zen Browser Nix flake package.

---

## 📜 License

This project is licensed under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)**.

- **Non-Commercial**: Free for individuals, students, hobbyists, and non-profit home labs. Strictly prohibited for commercial, enterprise, or corporate deployment without an explicit written license.
- **Attribution**: You must attribute original authorship to `nixx` and provide a direct link back to this repository.
- **Share-Alike**: Any adaptations, forks, or derivative works must be distributed under the exact same CC BY-NC-SA 4.0 license.
- **Media & Content Creation**: Creating tutorials, reviews, or videos discussing or showcasing this project (including on ad-supported platforms like YouTube) is welcome with attribution.

See the full [LICENSE](LICENSE) file for complete statutory definitions and terms.
