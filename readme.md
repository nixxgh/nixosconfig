# ❄️ Declarative Multi-Tenant Workstation Fleet

> An enterprise-grade, NixOS-based infrastructure-as-code platform supporting multi-user, multi-device deployments with blast-radius-controlled rebuild pipelines, unprivileged user-space management, LUKS disk encryption with TPM 2.0 auto-unlock, and zero-touch onboarding via fleet templates. Built on **Niri** (scrollable tiling Wayland compositor), tracking `nixos-unstable`.

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![flake-parts](https://img.shields.io/badge/framework-flake--parts-orange.svg)](https://github.com/hercules-ci/flake-parts)
[![Dendritic Architecture](https://img.shields.io/badge/pattern-dendritic%20autoloader-emerald.svg)](https://github.com/vic/import-tree)

---

> [!NOTE]
> ### 🌟 Looking to Build Your Own Fleet? Start Here:
> **This repository is the author's active daily-driver workstation (`fleet1`) and serves as the live, battle-tested reference implementation.** It contains personalized dotfiles (Niri, Neovim, Tmux), application suites, and physical hardware configs.
>
> - 🚀 **Recommended Starting Point**: If you are building your own fleet or looking for a clean, zero-bloat foundation, please use the official starter framework: **[`nixxgh/nixos-enterprise-fleet`](https://github.com/nixxgh/nixos-enterprise-fleet)**. It provides the pure turnkey scaffolding with zero personal data or technical debt to clean up.
> - 💻 **Using This Daily-Driver Setup**: You are fully welcome to clone, adapt, or study this configuration directly if you wish to replicate this exact Niri + Neovim environment, provided you abide by the **[CC BY-NC-SA 4.0 License](LICENSE)** (strictly non-commercial use, prominent attribution to `nixx`, and share-alike terms).

---

## 🏛️ Architectural Philosophy: The Fleet Model

Most NixOS repositories suffer from **configuration leakage**: machines are tangled with specific user accounts, and home-manager configurations are hardcoded to physical chassis. 

This platform completely decouples **Hardware**, **Fleet Policy**, and **User Identity** into three autonomous layers:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLEET 1 DOMAIN CAPSULE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   fleet-configuration/   ──► Shared workstation profile, daemons (audio,    │
│                              sddm, tailscale, ssh), programs (niri), sudo.  │
│                                                                             │
│   users/                 ──► Unprivileged team capsules (dotfiles, ZSH,     │
│                              neovim, tmux, packages). Roam across all devices.│
│                                                                             │
│   machines/              ──► Silicon & hardware scans only (LUKS UUIDs,     │
│                              partitions, CPU microcode). Zero user logic.   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Hardware as a Commodity**: A physical machine is just a block-storage scan. Adding a laptop or desktop takes 2 minutes by dropping a hardware scan into `machines/<name>/`.
2. **True Persona Roaming**: Any team member defined under `users/` exists on every machine in that fleet. Any member can log into any fleet workstation and immediately receive their identical shell, apps, and dotfiles.
3. **Blast-Radius Isolation**: Modifying a personal shell config never risks breaking the system kernel or display manager, and system-level daemon updates never reset or interrupt user sessions.

---

## 🏷️ The Golden Naming Convention & Machine Customization

A core design superpower of this platform is **zero-touch dynamic binding** driven by directory names:

```text
modules/hosts/fleet1/machines/<machine-name>/
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
While `fleet-configuration.nix` enforces uniform shared baseline rules across the **entire fleet** (all users, core daemons, audio, display manager, rebuild aliases), `<machine>-configuration.nix` gives you an isolated **Chassis Override Layer**:

- **Laptop Chassis** (e.g. `laptop-configuration.nix`):
  Enables touchpad tapping, lid-switch suspend/lock behavior, battery power governors, and screen backlight controls.
- **Dedicated GPU Workstation** (e.g. `desktop-configuration.nix`):
  Enables proprietary Nvidia drivers (`services.xserver.videoDrivers = [ "nvidia" ];`), multi-monitor display arrangements, and high-performance fan curves.
- **Headless Servers / Builders**:
  Disables display managers (`services.displayManager.sddm.enable = false;`) or mounts custom ZFS storage pools.

**Result**: You can customize every physical chassis to its silicon without polluting or altering the shared fleet configuration!

---

### 3. The User Capsule Contract (`<username>-configuration.nix`)
Just like machines, team members use the exact same directory-driven dynamic contract:

```text
modules/hosts/fleet1/users/<username>/
├── <username>-configuration.nix             <── User Capsule (Identity & Shell Aliases)
├── packages.nix                             <── Personal Userland Packages
└── programs/                                <── Modular Dotfiles (git, neovim, zsh, etc.)
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

Because every physical machine in the fleet imports `self.nixosModules.commonHost`, any user declared in `fleet-configuration.nix` **automatically applies to every machine in the fleet**:

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
│   Step 2: Wire into Fleet Blueprint (Single Point of Registration)          │
│   In modules/hosts/fleet1/fleet-configuration/users.nix:                    │
│     users.users.alice = { isNormalUser = true; ... };                       │
│     home-manager.users.alice = self.homeModules.alice;                      │
│                                                                             │
│                                      │                                      │
│                                      ▼                                      │
│                                                                             │
│   Step 3: Zero-Touch Cascading to ALL Fleet Devices                         │
│   ├── machine/laptop/      ──► Imports commonHost ──► Alice is provisioned! │
│   ├── machine/desktop/     ──► Imports commonHost ──► Alice is provisioned! │
│   └── machine/workstation/ ──► Imports commonHost ──► Alice is provisioned! │
│                                                                             │
│   Result: Alice's account, Home Manager dotfiles, and packages exist on     │
│   every physical computer in the fleet without touching any machine file.   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 5. Centralized Root Governance & Privilege Delegation

In an enterprise workstation fleet, **all root authority is strictly centralized in [`users.nix`](modules/hosts/fleet1/fleet-configuration/users.nix)**. Individual user capsules (`modules/hosts/fleet1/users/<username>/`) are completely unprivileged Home Manager modules and **cannot** elevate their own permissions or declare system services.

```text
┌────────────────────────────────────────────────────────────────────────┐
│             CENTRALIZED ROOT CONTROL & PRIVILEGE BOUNDARY              │
├────────────────────────────────────────────────────────────────────────┤
│  modules/hosts/fleet1/fleet-configuration/users.nix                    │
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
│      "wheel"          <── SUDO    │      "networkmanager"              │
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
    "input"          # Direct hardware input
  ];
};
```
Because `fleet-configuration.nix` specifies `nix.settings.trusted-users = [ "root" "@wheel" ]`, membership in `"wheel"` automatically grants communication with the Nix daemon, remote binary cache substitution, and execution of system-wide rebuild pipelines (`forcerebuildall`, `rebuildenvironment`).

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
Restricted users cannot modify system configuration, cannot alter hardware settings, and cannot access other users' data. They customize their tools and dotfiles purely via unprivileged Home Manager rebuilds (`rebuildhome` / `home-manager switch --flake .#devUser`).

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

Every fleet and machine instantiated from the templates inherits these immutable rebuild and maintenance pipelines:

| Command              | Target                  | Scope & Cascading Status                                                                 | Permission Level       |
| :------------------- | :---------------------- | :--------------------------------------------------------------------------------------- | :--------------------- |
| `forcerebuildall`    | `#${hostName}`          | Full atomic rebuild (**cascading** into all wired user home-manager profiles)            | Requires `sudo`        |
| `forceupdateall`     | `#${hostName}`          | Updates `flake.lock` and executes full cascading rebuild across machine and all users    | Requires `sudo`        |
| `forcecleanall`      | Both User & System      | Purges old HM & system generations, sweeps all garbage, and runs `nix store optimise`     | Requires `sudo`        |
| `rebuildenvironment` | `#${hostName}-env`      | Rebuilds system environment only (**non-cascading**; strips user space via `mkForce {}`) | Requires `sudo`        |
| `updateenvironment`  | `#${hostName}-env`      | Updates `flake.lock` and applies system-only rebuild                                      | Requires `sudo`        |
| `cleanenvironment`   | `#${hostName}-env`      | Purges old system generations, sweeps system garbage, and optimizes store                 | Requires `sudo`        |
| `rebuildhome`        | `#${userName}`          | Rebuilds user space only (`home-manager switch --flake .#<user>`)                        | **100% Unprivileged**  |
| `updatehome`         | `#${userName}`          | Updates `flake.lock` and rebuilds user space only                                        | **100% Unprivileged**  |
| `cleanhome`          | `#${userName}`          | Purges old user & Home Manager generations, collects user garbage (zero sudo required)   | **100% Unprivileged**  |
| `nixclean`           | Both User & System      | Alias to `forcecleanall` (for backward compatibility)                                    | Requires `sudo`        |

---

### 2. Workstation & Tooling Shortcuts (The Reference Implementation)

These are sample environment utilities wired specifically for machine `laptop` and user `nixx`. They are optional and can be replaced or extended per user:

| Command     | Tool / Component       | Description                                                                              |
| :---------- | :--------------------- | :--------------------------------------------------------------------------------------- |
| `ff`        | Fastfetch              | Displays Fastfetch system and hardware identity banner                                   |
| `autologin` | OpenSSH / SDDM / Niri  | Headless remote unlock script via SSH to initialize and unlock physical graphical session|
| `agui`      | Antigravity IDE        | Launches Antigravity AI-first development environment                                    |

---

## 🚀 System Capabilities & Features

### 1. Autonomous & Unattended Remote Operation
- **TPM 2.0 LUKS Auto-Unlock**: Root and swap volumes are enrolled into hardware TPM 2.0 (PCR registers 0+2) via `systemd-cryptenroll`. The machine boots autonomously after power cycles without manual passphrase entry, while keeping data securely encrypted at rest.
- **Wake-on-LAN (WoL)**: Multi-layer declarative WoL configuration on wired ethernet (`eno1` / MAC `14:cb:19:c4:b4:e5`) utilizing systemd `.link` files, NetworkManager connection profiles, udev rules, and dispatcher hooks.
- **Encrypted Mesh Networking**: Native **Tailscale** mesh VPN for zero-config, firewall-traversing remote access from anywhere.
- **Remote Desktop & Game Streaming**: **Sunshine** host server paired with **Moonlight** clients for ultra-low latency desktop streaming over Tailscale.
- **Remote Headless Login**: Lightweight SSH-based `autologin` script with passwordless sudo permissions to cleanly authenticate SDDM, initialize Niri, and unlock the physical session remotely.

### 2. Wayland Desktop (Niri)
- **Niri Compositor**: Modern scrollable tiling Wayland compositor configured declaratively via `nix-wrapper-modules`.
- **Maximized-by-Default Workflow**: Windows and columns open at 100% width and height by default for maximum screen real estate and zero distraction.
- **Vim-Centric Navigation**: Pure `Mod + HJKL` for column and workspace navigation, plus `Mod + Ctrl + HJKL` for moving columns and workspaces.
- **Subtle Aesthetics**: Dark `#000000` canvas background with refined Catppuccin-style grey focus rings (`#6c7086`).
- **SDDM Display Manager**: Clean Wayland greeter with legacy X11 desktop sessions and fallback `xterm` removed.

### 3. Developer & Terminal Environment
- **Shell**: **ZSH** equipped with Starship prompt, syntax highlighting, autosuggestions, and streamlined aliases.
- **Terminal**: **Alacritty** (GPU-accelerated) bound to `Mod + Return`, styled with JetBrainsMono Nerd Font.
- **Multiplexer**: **Tmux** with full 24-bit TrueColor (`RGB`), Vim navigation, and mouse support.
- **File Management**: **Yazi** terminal file manager with rich file previews, unarchiver plugins, and shell integrations.
- **Browsers**: **Zen Browser** (tracked via `zen-browser-flake` in Home Manager) and Firefox.
- **Containers & Dev Tools**: **Docker** daemon enabled at root, GitHub CLI (`gh`), Fastfetch (`ff`), and clipboard-integrated Neovim.

### 4. Self-Healing & Maintenance
- **Automated Garbage Collection**: Weekly pruning of generations older than 7 days (`nix.gc`).
- **Store Optimization**: Automated hard-linking and deduplication of identical store paths (`nix.settings.auto-optimise-store`).

---

## 📂 Repository Architecture

The repository is organized using the **Dendritic Pattern** (`flake-parts` + `import-tree`):

```text
myNixOS/
├── flake.nix                               # Entry point (inputs, flake-parts, auto-tree loader)
├── flake.lock                              # Pinned input revisions
├── LICENSE                                 # CC BY-NC-SA 4.0 Airtight License
├── readme.md                               # Project documentation
│
└── modules/
    ├── parts.nix                           # flake-parts assembly & host declaration
    │
    └── hosts/                              # ── PHYSICAL HOST & FLEET DOMAINS ──
        ├── _fleet_template/                # ── COMPLETE FLEET BLUEPRINT SKELETON ──
        │   ├── fleet-configuration/        # Fleet system policy & daemons
        │   ├── users/_template/            # User onboarding scaffold
        │   └── machines/_template/         # Machine onboarding scaffold
        │
        └── fleet1/                         # Fleet 1 Domain (Engineering Workstations)
            ├── fleet-configuration/        # Fleet 1 System Blueprint
            │   ├── fleet-configuration.nix # Common host base (daemons, rebuild aliases)
            │   ├── users.nix               # Fleet user registry & access control matrix
            │   ├── packages.nix            # Fleet system CLI packages
            │   ├── programs/               # Fleet-wide graphical programs
            │   │   └── niri.nix            # Niri compositor config & layout
            │   └── services/               # Fleet system services & daemons
            │       ├── audio.nix           # PipeWire & WirePlumber audio stack
            │       ├── bluetooth.nix       # Bluetooth daemon & power defaults
            │       ├── home-manager.nix    # Home Manager integration module
            │       ├── sddm.nix            # SDDM display manager configuration
            │       ├── ssh.nix             # OpenSSH server & remote session control
            │       ├── sunshine.nix        # Sunshine remote desktop streaming
            │       ├── tailscale.nix       # Tailscale mesh VPN integration
            │       └── wakeonlan.nix       # Declarative Wake-on-LAN rules
            │
            ├── users/                      # Fleet 1 User Roster (Home Manager)
            │   ├── nixx/                   # Active user capsule: nixx
            │   │   ├── nixx-configuration.nix # User capsule (rebuildhome, updatehome, cleanhome)
            │   │   ├── packages.nix        # Userland packages (home.packages)
            │   │   ├── programs/           # 11 personal dotfiles & app configurations
            │   │   │   ├── alacritty.nix   # Alacritty terminal emulator
            │   │   │   ├── antigravity.nix # Antigravity CLI environment
            │   │   │   ├── direnv.nix      # Direnv shell environment switcher
            │   │   │   ├── fastfetch.nix   # System info banner configuration
            │   │   │   ├── firefox.nix     # Web browser
            │   │   │   ├── git.nix         # Git identity & global configuration
            │   │   │   ├── neovim.nix      # Neovim text editor
            │   │   │   ├── tmux.nix        # Tmux terminal multiplexer
            │   │   │   ├── yazi.nix        # Yazi terminal file manager
            │   │   │   ├── zen.nix         # Zen Browser configuration
            │   │   │   └── zsh.nix         # ZSH shell, prompt, and custom aliases
            │   │   └── services/           # User background daemons
            │   │
            │   └── _template/              # ── TURNKEY USER ONBOARDING TEMPLATE ──
            │       ├── template-configuration.nix # Auto-binding user capsule template
            │       ├── packages.nix        # User packages template
            │       ├── programs/git.nix    # Personal Git identity template
            │       └── services/           # User daemons template
            │
            └── machines/                   # Physical Fleet 1 Devices
                ├── _template/              # ── TURNKEY MACHINE ONBOARDING TEMPLATE ──
                │   ├── template-configuration.nix
                │   └── template-hardware-configuration.nix
                │
                └── laptop/                 # Laptop machine profile (#laptop / #laptop-env)
                    ├── laptop-configuration.nix        # Dynamic host binding (#laptop, -env)
                    └── laptop-hardware-configuration.nix # LUKS UUIDs & physical disk scan
```

---

## 🧭 The 3-Tier Onboarding Protocol

> **Rule of Thumb**: Always base new deployments on the unopinionated `_template` blueprints rather than copying live machine profiles. The templates feature dynamic binding (`baseNameOf ./.`), clean defaults, and zero personal credentials.

### Tier 1: Onboarding a New Machine to an Existing Fleet
To add another physical laptop or workstation to `fleet1` (e.g. `desktop`):

```bash
# 1. Create the new machine directory in fleet1
mkdir -p modules/hosts/fleet1/machines/desktop

# 2. Copy the machine templates directly from fleet1/machines/_template
cp modules/hosts/fleet1/machines/_template/template-configuration.nix modules/hosts/fleet1/machines/desktop/desktop-configuration.nix
cp modules/hosts/fleet1/machines/_template/template-hardware-configuration.nix modules/hosts/fleet1/machines/desktop/desktop-hardware-configuration.nix

# 3. Populate hardware scan into desktop-hardware-configuration.nix:
# Run: nixos-generate-config --show-hardware-config
# Copy the generated filesystem, kernel modules, and root LUKS lines into the module body.

# 4. Dry-build to verify syntax and hardware bindings
nix build .#nixosConfigurations.desktop.config.system.build.toplevel --no-link

# 5. Apply the switch
sudo nixos-rebuild switch --flake .#desktop
```
*(Notice: Because `desktop-configuration.nix` uses `hostName = baseNameOf ./.`, it automatically provisions all fleet users and exports `#desktop` and `#desktop-env` without manual editing).*

> ⚠️ **The Calamares / Encrypted Swap Gotcha**:
> If the machine was installed with encrypted swap using the NixOS GUI installer (Calamares), check your old `/etc/nixos/configuration.nix`! Calamares dumps the swap LUKS mapping (`boot.initrd.luks.devices."luks-<swap-uuid>"...`) and `boot.resumeDevice` into `configuration.nix` instead of `hardware-configuration.nix`.
> **Action**: Ensure you copy those two declarations from your old `configuration.nix` into `<machine>-hardware-configuration.nix` so your encrypted swap unlocks autonomously during initrd boot!

---

### Tier 2: Onboarding a New Team Member / User
To add a new user (e.g. `alice`) to `fleet1`:

```bash
# 1. Copy the user template capsule
cp -r modules/hosts/fleet1/users/_template modules/hosts/fleet1/users/alice

# 2. Rename the configuration file
mv modules/hosts/fleet1/users/alice/template-configuration.nix modules/hosts/fleet1/users/alice/alice-configuration.nix

# 3. Set personal Git identity in:
# nano modules/hosts/fleet1/users/alice/programs/git.nix

# 4. In modules/hosts/fleet1/fleet-configuration/users.nix, register alice and assign permissions:
# Copy the template from Section 2 into Section 3:
# users.users.alice = { isNormalUser = true; description = "alice"; shell = pkgs.zsh; extraGroups = [ "networkmanager" ]; };
# home-manager.users.alice = self.homeModules.alice;

# 5. Rebuild:
forcerebuildall
```
*(Alice now exists across every physical device in Fleet 1 and can independently rebuild her dotfiles anytime using `rebuildhome`).*

---

### Tier 3: Onboarding a Whole New Fleet Domain
To create an isolated second fleet (e.g. `fleet2` for another team or dedicated server fleet):

```bash
# 1. Copy the turnkey fleet blueprint
cp -r modules/hosts/_fleet_template modules/hosts/fleet2

# 2. Adjust fleet-wide policy, daemons, and packages in:
# modules/hosts/fleet2/fleet-configuration/fleet-configuration.nix

# 3. Add machines and users to fleet2 using Tier 1 and Tier 2 workflows.
```

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
| `Ctrl + h/j/k/l`          | Normal         | Pane Navigation  | Seamless navigation between Neovim splits and Tmux panes           |
| `<leader>a`               | Normal         | Harpoon Add      | Pin current file into Harpoon                                      |
| `<leader>h` / `<C-e>`     | Normal         | Harpoon Menu     | Toggle Harpoon quick menu list                                     |
| `<leader>1` - `<leader>4` | Normal         | Harpoon Jump     | Jump directly to pinned file 1–4                                   |

### 2. Niri (Wayland Compositor)
- **Modifier Key (`Mod`)**: `Super` (Windows key)

| Keybinding                       | Action               | Description                                             |
| :------------------------------- | :------------------- | :------------------------------------------------------ |
| `Mod + Return`                   | Terminal             | Opens GPU-accelerated **Alacritty** terminal            |
| `Mod + S`                        | App Launcher         | Toggles **Fuzzel** application launcher                 |
| `Mod + Shift + S` / `Print`      | Quick Snip           | Select region -> auto-copied to clipboard & saved (zero GUI) |
| `Mod + Alt + S` / `Shift + Print`| Annotated Capture    | Select region into **Satty** editor (draw, arrows, text, blur) |
| `Mod + N`                        | Notification Center  | Toggles **SwayNC** notification control center          |
| `Mod + Q`                        | Close Window         | Closes the currently focused window                     |
| `Mod + Shift + E`                | Quit Niri            | Exits the compositor session back to SDDM               |
| `Mod + Shift + /`                | Hotkey Help          | Toggles Niri's interactive hotkey cheat-sheet overlay   |
| `Mod + H / L`                    | Focus Column L/R     | Moves focus to the adjacent column                      |
| `Mod + K / J`                    | Focus Workspace Up/Dn| Moves focus to workspace above / below                  |
| `Mod + Ctrl + H / L`             | Move Column L/R      | Shifts active column left / right                       |
| `Mod + Ctrl + K / J`             | Move Column Up/Dn    | Shifts active column to workspace above / below         |
| `Mod + F`                        | Maximize Column      | Toggles column maximization (100% width/height)         |
| `Mod + R`                        | Cycle Preset Width   | Cycles configured column widths                         |
| `Mod + ,` / `.`                  | Consume / Expel      | Pulls/pushes adjacent window into current column        |
| `Mod + Space`                    | Float / Tile Toggle  | Switches focus between floating and tiling layers       |
| `Mod + Tab`                      | Workspace Overview   | Toggles bird's-eye workspace overview                   |
| `XF86AudioRaiseVolume` / `Lower` | Volume ±5%           | Adjusts master volume via WirePlumber (`wpctl`)         |
| `XF86AudioMute`                  | Mute Audio           | Toggles audio sink mute via WirePlumber                 |
| `XF86MonBrightnessUp` / `Down`   | Brightness ±5%       | Adjusts screen brightness via `brightnessctl`           |

---

## 🌟 Acknowledgements & Upstream Credits

This architecture stands on the shoulders of giants. Building this declarative, multi-tenant workstation fleet would not have been possible without the following five foundational open-source technologies and their creators:

1. **[NixOS & Nixpkgs](https://github.com/NixOS/nixpkgs)** (by _Eelco Dolstra and the Nix community_) — For the pure functional package manager and declarative operating system core.
2. **[Home Manager](https://github.com/nix-community/home-manager)** (by _Robert Helgesson and the nix-community_) — For declarative, unprivileged user-space environment management.
3. **[flake-parts](https://github.com/hercules-ci/flake-parts)** (by _Hercules CI & Robert Hensing_) — For the modular flake framework enabling clean separation of concerns.
4. **[nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)** (by _BirdeeHub_) — For declarative, robust application wrapper configurations.
5. **[import-tree](https://github.com/vic/import-tree)** (by _Victor Borja_) — For the zero-boilerplate filesystem crawler that dynamically discovers and auto-loads our fleet modules.

---

## 📜 License

This project is licensed under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)**.

- **Non-Commercial**: Free for individuals, students, hobbyists, and non-profit home labs. Strictly prohibited for commercial, enterprise, or corporate deployment without an explicit written license.
- **Attribution**: You must attribute original authorship to `nixx` and provide a direct link back to this repository.
- **Share-Alike**: Any adaptations, forks, or derivative works must be distributed under the exact same CC BY-NC-SA 4.0 license.
- **Media & Content Creation**: Creating tutorials, reviews, or videos discussing or showcasing this project (including on ad-supported platforms like YouTube) is welcome with attribution.

See the full [LICENSE](LICENSE) file for complete statutory definitions and terms.
