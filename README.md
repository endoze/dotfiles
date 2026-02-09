# Nix Dotfiles Configuration

Multi-platform Nix Flakes configuration managing macOS (aarch64-darwin) and NixOS (x86_64-linux) machines with home-manager, nix-darwin, and NixOS.

## Available Configurations

### Home Manager Configurations
- `macbook` (aarch64-darwin) - Personal MacBook
- `workmac` (aarch64-darwin) - Work MacBook
- `deadmau5` (x86_64-linux) - Linux desktop with Hyprland, NVIDIA GPU, gaming
- `tiesto` (x86_64-linux) - Apple T2 MacBook running NixOS
- `dosvec` (x86_64-linux) - Headless home server (k3s, ZFS, NVIDIA, Coral TPU)
- `docker` (x86_64-linux) - Docker container

### Darwin (macOS) System Configurations
- `macbook` - Personal MacBook system configuration
- `workmac` - Work MacBook system configuration

### NixOS System Configurations
- `deadmau5` - Linux desktop (Hyprland, gaming, NVIDIA)
- `tiesto` - T2 MacBook with Linux (CachyOS kernel, T2 firmware)
- `dosvec` - Headless server (k3s, ZFS, NVIDIA, Coral TPU, sops-nix secrets)

## Structure

```
.
├── flake.nix                  # Main flake configuration
├── flake.lock                 # Locked flake dependencies
├── Dockerfile                 # Nix-based Docker image definition
├── .sops.yaml                 # Secret encryption configuration (age keys)
├── bin/                       # Custom scripts
├── secrets/                   # Encrypted secret files (sops-nix)
├── wallpapers/                # Wallpaper files
├── config/                    # Actual configuration files
│   ├── bat/                   # Syntax highlighter config
│   ├── fish/                  # Fish shell (aliases, functions, completions)
│   ├── ghostty/               # Ghostty terminal config
│   ├── hypr/                  # Hyprland compositor config
│   ├── karabiner/             # macOS keyboard remapping
│   ├── kitty/                 # Kitty terminal config
│   ├── lsd/                   # lsd (ls alternative) config
│   ├── mise/                  # Runtime version manager config
│   ├── nvim/                  # Neovim configuration
│   ├── rofi/                  # Application launcher config
│   ├── sddm/                  # Login screen theme
│   ├── swaync/                # Notification center config
│   ├── tmux/                  # Tmux configuration
│   ├── wallust/               # Color scheme generator config
│   ├── waybar/                # Status bar config
│   ├── weechat/               # IRC client config
│   └── ...                    # Other tool configs
└── modules/                   # All Nix configuration modules
    ├── home/                  # Home-manager configurations
    │   ├── default.nix        # Common home configuration
    │   ├── darwin.nix         # macOS-specific home config
    │   ├── linux.nix          # Linux-specific home config
    │   ├── common/            # Shared tool modules
    │   │   ├── bat.nix        # bat (cat alternative)
    │   │   ├── databases.nix  # Database service configs
    │   │   ├── fish.nix       # Fish shell
    │   │   ├── ghostty.nix    # Ghostty terminal
    │   │   ├── git.nix        # Git configuration
    │   │   ├── jujutsu.nix    # Jujutsu VCS
    │   │   ├── mise.nix       # Runtime version manager
    │   │   ├── neovim.nix     # Neovim (LSPs, formatters, tools)
    │   │   ├── ruby.nix       # Ruby environment
    │   │   ├── starship.nix   # Starship prompt
    │   │   ├── tmux.nix       # Tmux multiplexer
    │   │   └── ...            # More tool modules
    │   ├── darwin/            # macOS-only modules
    │   │   ├── alerter.nix    # System notifications
    │   │   └── karabiner.nix  # Keyboard remapping
    │   ├── linux/             # Linux-only modules
    │   │   ├── hyprland.nix   # Wayland compositor
    │   │   ├── waybar.nix     # Status bar
    │   │   ├── rofi.nix       # App launcher
    │   │   ├── swaync.nix     # Notification daemon
    │   │   └── ...            # More linux modules
    │   └── meta/              # Meta-modules (bundles of tools)
    │       ├── cli.nix        # Common CLI tools bundle
    │       ├── gui-darwin.nix # macOS GUI applications bundle
    │       └── gui-linux.nix  # Linux GUI applications bundle
    ├── machines/              # Machine-specific configurations
    │   ├── macbook/           # Personal MacBook
    │   ├── workmac/           # Work MacBook
    │   ├── deadmau5/          # Linux desktop
    │   ├── tiesto/            # T2 MacBook with Linux
    │   ├── dosvec/            # Headless server
    │   └── docker/            # Docker container
    ├── system/                # System-level configurations
    │   ├── darwin/            # macOS system config (dnsmasq, php)
    │   ├── nixos/             # NixOS system config (docker, k3s, nvidia, zfs, etc.)
    │   └── meta/              # System-level package bundles
    └── users/                 # User configuration
        ├── default.nix        # Loads local.nix or uses defaults
        ├── docker.nix         # Docker-specific user config
        └── example.nix        # Template for users/local.nix
```

## Local Configuration (for Personal Info)

To keep personal information out of this public repository, a local configuration file that is not committed to git is used. The configuration dynamically reads from this file when using the `--impure` flag.

### Setup

1. Copy the example configuration:
   ```bash
   cp modules/users/example.nix modules/users/local.nix
   ```

2. Edit `modules/users/local.nix` with your actual information:
   ```nix
   {
     username = "your-username";
     fullName = "Your Name";
     userEmail = "your-email@example.com";
     gpgKey = "";  # optional GPG key ID

     # System configuration
     hostName = "your-hostname";
     computerName = "Your Computer Name";  # macOS only
   }
   ```

3. Use the configuration with `--impure` flag:
   ```bash
   home-manager switch --flake .#macbook --impure
   home-manager switch --flake .#workmac --impure
   home-manager switch --flake .#deadmau5 --impure

   # Or use the provided fish shell functions (already include --impure)
   nix-home    # for home-manager
   nix-system  # for darwin-rebuild / nixos-rebuild
   ```

### How it Works

- `modules/users/default.nix` checks for `modules/users/local.nix` at runtime
- When running with `--impure`, it reads from `$HOME/.dotfiles/modules/users/local.nix`
- If the local file doesn't exist, it falls back to generic placeholders
- The local file is git-ignored and will never be committed to the repository
- Each machine uses the same local config file - just one set of values for all configurations

### Important Notes

- **Always use the `--impure` flag** when switching configurations that use local config
- Your actual username and hostname are read from the local config file, not the flake attribute name

## Initial Setup

### 1. Install Nix

```bash
# macOS/Linux (Determinate Systems installer - includes flakes)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

### 2. Clone Repository

```bash
git clone https://github.com/endoze/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. First-Time Bootstrap

Since `darwin-rebuild`, `nixos-rebuild`, and `home-manager` commands aren't available until after the first run, use these bootstrap commands:

#### System Configurations

```bash
# macOS (nix-darwin) - Personal MacBook
nix build .#darwinConfigurations.macbook.system --impure
sudo ./result/sw/bin/darwin-rebuild switch --flake .#macbook --impure

# macOS (nix-darwin) - Work MacBook
nix build .#darwinConfigurations.workmac.system --impure
sudo ./result/sw/bin/darwin-rebuild switch --flake .#workmac --impure

# NixOS (replace <machine> with deadmau5, tiesto, or dosvec)
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel --impure
sudo ./result/bin/switch-to-configuration switch
```

#### Home-Manager Standalone

```bash
# macOS - Personal MacBook
nix build .#homeConfigurations.macbook.activationPackage --impure
./result/activate

# macOS - Work MacBook
nix build .#homeConfigurations.workmac.activationPackage --impure
./result/activate

# Linux (replace <machine> with deadmau5, tiesto, or dosvec)
nix build .#homeConfigurations.<machine>.activationPackage --impure
./result/activate
```

## Ongoing Usage

After the initial setup, use these consistent commands:

### Using Shell Functions (Recommended)

Once fish shell is configured, use these functions which automatically detect your machine and include the `--impure` flag:

```bash
nix-home    # Update home-manager configuration
nix-system  # Update system configuration (darwin-rebuild / nixos-rebuild)
```

### Manual Commands

#### System Configurations

```bash
# macOS (nix-darwin)
sudo darwin-rebuild switch --flake ~/.dotfiles#macbook --impure
sudo darwin-rebuild switch --flake ~/.dotfiles#workmac --impure

# NixOS (replace <machine> with deadmau5, tiesto, or dosvec)
sudo nixos-rebuild switch --flake ~/.dotfiles#<machine> --impure
```

#### Home-Manager Standalone

```bash
# macOS
home-manager switch --flake ~/.dotfiles#macbook --impure
home-manager switch --flake ~/.dotfiles#workmac --impure

# Linux (replace <machine> with deadmau5, tiesto, or dosvec)
home-manager switch --flake ~/.dotfiles#<machine> --impure
```

### Docker

```bash
docker build -t dotfiles .
```

## Customization

1. **Personal information**: Create `modules/users/local.nix` from the example template (see Local Configuration section above)
2. **Add new packages**: Edit `modules/home/meta/cli.nix` for CLI tools, or the relevant `gui-darwin.nix`/`gui-linux.nix` for GUI applications
3. **Add new tool modules**: Create a module in `modules/home/common/` (shared), `modules/home/darwin/` (macOS), or `modules/home/linux/` (Linux) and import it in the corresponding `default.nix`
4. **Machine-specific settings**: Edit files in `modules/machines/<machine>/`
5. **New machines**: Add a directory under `modules/machines/`, create `home.nix` and/or `system.nix`, and add the configuration to `flake.nix`

## Common Commands

```bash
# Update all flake inputs
nix flake update

# Check flake configuration
nix flake check

# Show flake info
nix flake show

# Garbage collection
nix-collect-garbage -d

# Search for packages
nix search nixpkgs <package-name>
```
