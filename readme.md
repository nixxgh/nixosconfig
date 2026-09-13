# ❄️ myNixOS

> Fully declarative, flake-based NixOS workstation and remote powerhouse tracking `nixos-unstable`. Built around the **Niri** scrollable tiling compositor, automated **TPM 2.0 / Wake-on-LAN** remote access, and modular **Home Manager** dotfiles.

---

## 🚀 System Capabilities & Highlights

### 1. Autonomous & Unattended Remote Operation
* **TPM 2.0 LUKS Auto-Unlock**: Root and swap volumes are enrolled into hardware TPM 2.0 (PCR registers 0+2) via `systemd-cryptenroll`. The machine boots autonomously after power cycles without requiring manual passphrase entry, while keeping data securely encrypted at rest.
* **Wake-on-LAN (WoL)**: Multi-layer declarative WoL configuration on wired ethernet (`eno1` / MAC `14:cb:19:c4:b4:e5`) utilizing systemd `.link` files, NetworkManager connection profiles, udev rules, and dispatcher hooks.
* **Encrypted Mesh Networking**: Native **Tailscale** mesh VPN for zero-config, firewall-traversing remote access from any device.
* **Remote Desktop & Game Streaming**: **Sunshine** host server paired with **Moonlight** clients for high-performance, low-latency desktop streaming to phones, tablets, or laptops over Tailscale.
* **Remote Headless Login**: Lightweight SSH-based `autologin` / `autounlock` script with passwordless sudo permissions to cleanly authenticate SDDM, initialize Niri, and unlock the physical session remotely.

### 2. Wayland Desktop (Niri + Noctalia)
* **Niri Compositor**: Modern scrollable tiling Wayland compositor configured declaratively via `nix-wrapper-modules`.
* **Maximized-by-Default Workflow**: Windows and columns open at 100% width and height by default for maximum screen real estate and zero distraction.
* **Vim-Centric Navigation**: Pure `Mod + HJKL` for column and workspace navigation (arrow key binds removed), plus `Mod + Ctrl + HJKL` for moving columns and workspaces.
* **Subtle Aesthetics**: Dark `#000000` canvas background with refined Catppuccin-style grey focus rings (`#6c7086`).
* **Shell & Bar**: **Noctalia** launcher and status bar with automated config export workflows (`ncupdate`).
* **SDDM Display Manager**: Clean Wayland greeter with legacy X11 desktop sessions and fallback `xterm` removed.

### 3. Developer & Terminal Environment
* **Shell**: **ZSH** equipped with Starship prompt, syntax highlighting, autosuggestions, and streamlined aliases.
* **Terminal**: **Alacritty** (GPU-accelerated) bound to `Mod + Return`, styled with JetBrainsMono Nerd Font.
* **Multiplexer**: **Tmux** with full 24-bit TrueColor (`RGB`), Vim navigation, and mouse support.
* **File Management**: **Yazi** terminal file manager with rich file previews, unarchiver plugins, and shell integrations.
* **Browsers**: **Zen Browser** (tracked via `zen-browser-flake` in Home Manager) and Firefox.
* **Containers & Dev Tools**: **Docker** daemon enabled at root, GitHub CLI (`gh`), Fastfetch (`ff`), and clipboard-integrated Neovim.

### 4. Self-Healing & Maintenance
* **Automated Garbage Collection**: Weekly pruning of generations older than 7 days (`nix.gc`).
* **Store Optimization**: Automated hard-linking and deduplication of identical store paths (`nix.settings.auto-optimise-store`).
* **One-Step System Updates**: Custom `rebuild` alias that automatically stages, commits, pushes git changes, and applies the NixOS configuration switch in one command.

---

## 📂 Repository Architecture

The repository is organized using `flake-parts` and `import-tree` to automatically load modules without manual import boilerplate:

```text
myNixOS/
├── flake.nix                               # Entry point (inputs, flake-parts, auto-tree loader)
├── flake.lock                              # Pinned input revisions
├── readme.md                               # This documentation
├── Nixos.txt                               # Roadmap and implementation tracker
│
└── modules/
    ├── parts.nix                           # flake-parts assembly & host declaration
    │
    ├── hosts/
    │   └── my-machine/
    │       ├── configuration.nix           # Host chassis, aliases, users, bootloader, GC
    │       └── hardware-configuration.nix  # Kernel modules, mounts, LUKS storage mapping
    │
    ├── features/                           # System-level modules & OS services
    │   ├── audio.nix                       # PipeWire & WirePlumber audio stack
    │   ├── bluetooth.nix                   # Bluetooth daemon & power defaults
    │   ├── home-manager.nix                # Home Manager integration module
    │   ├── niri.nix                        # Niri compositor config, keybindings, layout
    │   ├── noctalia.nix                    # Noctalia shell & bar integration
    │   ├── .noctalia-config.toml           # Exported Noctalia theme & widget configuration
    │   ├── sddm.nix                        # SDDM display manager configuration
    │   ├── ssh.nix                         # OpenSSH server daemon
    │   ├── sunshine.nix                    # Sunshine remote desktop streaming service
    │   ├── tailscale.nix                   # Tailscale mesh VPN integration
    │   └── wakeonlan.nix                   # Declarative Wake-on-LAN rules (link, udev, nm)
    │
    └── home/                               # User-space configuration (Home Manager)
        ├── nixx.nix                        # User entry point (imports user features)
        └── features/                       # Modular user application configs
            ├── fastfetch.nix               # System info banner configuration
            ├── firefox.nix                 # Secondary web browser
            ├── git.nix                     # Git identity & global configuration
            ├── neovim.nix                  # Neovim text editor
            ├── tmux.nix                    # Tmux terminal multiplexer
            ├── yazi.nix                    # Yazi terminal file manager
            ├── zen.nix                     # Zen Browser configuration
            └── zsh.nix                     # ZSH shell, prompt, and custom aliases
```

---

## 📥 Deployment & Adoption Guide (Cloning to Another Machine)

If you are pulling this configuration onto your own system, NixOS makes reproducing the environment seamless. However, because NixOS directly interacts with your physical storage and network interfaces, there are **3 hardware-specific prerequisites** you must verify before rebuilding.

### 1. Hardware Prerequisites

1. **Hardware Configuration & Disks (`modules/hosts/my-machine/hardware-configuration.nix`)**:
   Every machine has different storage UUIDs, disk controllers, and CPU microcode. Generate a clean hardware profile for your target machine:
   ```bash
   nixos-generate-config --show-hardware-config > modules/hosts/my-machine/hardware-configuration.nix
   ```

2. **LUKS Disk Encryption (`modules/hosts/my-machine/configuration.nix`)**:
   This workstation configuration assumes a LUKS-encrypted root volume.
   * If your system **does not use disk encryption**: remove or comment out the `boot.initrd.luks.devices` declaration in `configuration.nix` (line 34).
   * If your system **uses a different LUKS partition**: update the UUID to match your disk's encrypted partition UUID.

3. **Wake-on-LAN & Networking (`modules/features/wakeonlan.nix`)**:
   The Wake-on-LAN module is configured specifically for interface `eno1` and MAC `14:cb:19:c4:b4:e5`.
   * If adopting WoL: update the interface name and MAC address in `modules/features/wakeonlan.nix`.
   * If not needed: comment out `self.nixosModules.wakeonlan` in `modules/hosts/my-machine/configuration.nix`.

4. **Username & Git Identity**:
   * The primary user account is set to `nixx` in `modules/hosts/my-machine/configuration.nix` and `modules/home/nixx.nix`.
   * Personal Git identity is configured in `modules/home/features/git.nix`.

---

### 2. Step-by-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/nixxgh/myNixOS.git ~/myNixOS
cd ~/myNixOS

# 2. Extract your machine's hardware configuration
nixos-generate-config --show-hardware-config > modules/hosts/my-machine/hardware-configuration.nix

# 3. Adjust LUKS / Network settings as detailed above
# nano modules/hosts/my-machine/configuration.nix

# 4. Dry-build to verify syntax and dependencies
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel --no-link

# 5. Apply and switch to the configuration
sudo nixos-rebuild switch --flake .#myMachine
```

---

## ⌨️ Common Shell Aliases & Commands

| Command | Action |
| :--- | :--- |
| `rebuild` | Auto-stages, commits, pushes git changes, and runs `nixos-rebuild switch --flake .#myMachine` |
| `update` | Updates all flake inputs, verifies with an isolated test-build, and runs `rebuild` |
| `ncupdate` | Exports live Noctalia configuration directly to `modules/features/.noctalia-config.toml` |
| `nixclean` | Runs user and system garbage collection and optimizes store hard links |
| `ff` | Launches Fastfetch system information summary |
| `autologin` / `autounlock` | Headless remote unlock script via SSH to initialize graphical session |

---

## ⌨️ Application-Specific Keybindings

### 1. Neovim (`nvim`)
* **Leader Key**: `<Space>`

| Keybinding | Mode | Action | Description |
| :--- | :--- | :--- | :--- |
| `<leader>cf` | Normal, Visual | Format Code | Formats current buffer/selection using `conform.nvim` (`nixfmt` for Nix, `prettier` for Astro/TS/JS/CSS) |
| `<leader>ff` | Normal | Find Files | Telescope fuzzy file finder across project |
| `<leader>fg` | Normal | Live Grep | Telescope ripgrep text search across all project files |
| `<leader>fb` | Normal | Buffers | Telescope open buffer list |
| `K` | Normal | LSP Hover | Displays type definitions, signatures, and documentation in a popup |
| `gd` | Normal | Go to Definition | Jumps to source definition of symbol under cursor |
| `gr` | Normal | Go to References | Lists all symbol references across the workspace |
| `<leader>rn` | Normal | Rename Symbol | Project-wide symbol rename via LSP |
| `<leader>ca` | Normal | Code Action | Quick fixes and refactoring actions |
| `<leader>d` | Normal | Line Diagnostics | Shows diagnostics/errors for current line in a floating window |
| `[d` / `]d` | Normal | Diagnostic Nav | Jump to previous / next diagnostic warning or error |
| `Ctrl + h/j/k/l` | Normal | Pane Navigation | Seamless navigation between Neovim splits and Tmux panes |
| `<leader>a` | Normal | Harpoon Add | Pin/bookmark current file into Harpoon |
| `<leader>h` / `<C-e>` | Normal | Harpoon Menu | Toggle Harpoon quick menu list |
| `<leader>1` - `<leader>4` | Normal | Harpoon Jump | Jump directly to pinned file 1, 2, 3, or 4 |

> **Note**: `format_on_save` is also enabled by default via `conform.nvim` (with a 1000ms timeout and LSP fallback).

### 2. Niri (Scrollable Tiling Compositor)
* **Modifier Key (`Mod`)**: `Super` (Windows key)

| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `Mod + Return` | Terminal | Opens GPU-accelerated **Alacritty** terminal |
| `Mod + S` | Launcher | Toggles the **Noctalia** application launcher |
| `Mod + Q` | Close Window | Closes the currently focused window |
| `Mod + Shift + E` | Quit Niri | Exits the compositor session back to SDDM |
| `Mod + Shift + /` | Hotkey Help | Toggles Niri's interactive hotkey cheat-sheet overlay |
| **Vim Navigation** | | |
| `Mod + H` | Focus Column Left | Moves focus to the adjacent column on the left |
| `Mod + L` | Focus Column Right | Moves focus to the adjacent column on the right |
| `Mod + K` | Focus Workspace Up | Moves focus to the workspace above |
| `Mod + J` | Focus Workspace Down | Moves focus to the workspace below |
| **Vim Movement** | | |
| `Mod + Ctrl + H` | Move Column Left | Shifts the active column left |
| `Mod + Ctrl + L` | Move Column Right | Shifts the active column right |
| `Mod + Ctrl + K` | Move Column Up | Moves the active column to the workspace above |
| `Mod + Ctrl + J` | Move Column Down | Moves the active column to the workspace below |
| **Layout & Windows** | | |
| `Mod + F` | Maximize Column | Toggles column maximization |
| `Mod + R` | Switch Preset Width | Cycles configured column widths |
| `Mod + ,` (Comma) | Consume/Expel Left | Pulls/pushes adjacent window into current column |
| `Mod + .` (Period) | Consume/Expel Right | Pulls/pushes adjacent window into current column |
| `Mod + Shift + F` | Toggle Floating | Toggles focused window between floating and tiling mode |
| `Mod + Space` | Toggle Float Focus | Switches focus between floating and tiling layers |
| `Mod + Tab` | Workspace Overview | Toggles bird's-eye workspace and column overview |
| **Hardware & Media** | | *(Universal keys, enabled even when session is locked)* |
| `XF86AudioRaiseVolume` / `Lower` | Volume ±5% | Adjusts master volume via WirePlumber (`wpctl`) |
| `XF86AudioMute` / `MicMute` | Mute Audio / Mic | Toggles audio sink or source mute via WirePlumber |
| `XF86MonBrightnessUp` / `Down` | Brightness ±5% | Adjusts screen brightness via `brightnessctl` |
| `XF86AudioPlay` / `Pause` | Play / Pause | Media control via `playerctl` |
| `XF86AudioNext` / `Prev` | Next / Previous | Track control via `playerctl` |

## 🔧 Hardware & Host Details

* **Chassis / Hostname**: `nixos` (`myMachine`)
* **Architecture**: `x86_64-linux`
* **File System**: LUKS Encrypted on NVMe with TPM 2.0 auto-unlock
* **Network Interface**: `eno1` (1GbE wired with WoL enabled)

