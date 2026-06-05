# Nix Dotfiles Configuration

Multi-platform Nix Flakes configuration managing macOS (aarch64-darwin) and NixOS (x86_64-linux) machines with home-manager, nix-darwin, and NixOS.

## Available Configurations

### Home Manager Configurations
- `macbook` (aarch64-darwin) - Personal MacBook
- `workmac` (aarch64-darwin) - Work MacBook
- `deadmau5` (x86_64-linux) - Linux desktop with Hyprland, NVIDIA GPU, gaming
- `dosvec` (x86_64-linux) - Headless home server (k3s, ZFS, NVIDIA, Coral TPU)
- `docker` (x86_64-linux) - Docker container

### Darwin (macOS) System Configurations
- `macbook` - Personal MacBook system configuration
- `workmac` - Work MacBook system configuration

### NixOS System Configurations
- `deadmau5` - Linux desktop (Hyprland, gaming, NVIDIA)
- `dosvec` - Headless server (k3s, ZFS, NVIDIA, Coral TPU, sops-nix secrets)

## Structure

```
.
├── flake.nix       # Entry point: inputs, machine registry, output builders
├── flake.lock      # Locked flake dependencies
├── Dockerfile      # Nix-based Docker image definition
├── .sops.yaml      # Secret encryption config (age keys)
├── bin/            # Custom scripts
├── secrets/        # Encrypted secret files (sops-nix)
├── wallpapers/     # Wallpaper files
├── lib/            # Flake helpers: machine registry + system/home builders
├── config/         # Raw, non-Nix config files, one dir per tool (e.g. nvim/, hypr/)
│                   #   symlinked into place by a module under modules/
└── modules/        # All Nix configuration
    ├── home/       # Home-manager (per-user)
    │   ├── common/ #   cross-platform, one .nix per tool
    │   ├── darwin/ #   macOS-only
    │   ├── linux/  #   Linux-only
    │   └── meta/   #   bundles that import many tool modules (cli, gui-*)
    ├── system/     # System-level (nix-darwin / NixOS)
    │   ├── darwin/ #   macOS system services
    │   ├── nixos/  #   NixOS system services
    │   └── meta/   #   system package/service bundles
    └── machines/   # Per-machine entry points (one dir per host) that
                    #   compose the meta bundles + machine-specific tweaks
```

**Where things live / where to add stuff:**

- **A tool's raw config** (dotfiles it reads at runtime) → `config/<tool>/`. A
  module symlinks it into place; nothing reads `config/` directly.
- **A new tool/program** → a `.nix` under `modules/home/{common,linux,darwin}/`
  (user-level) or `modules/system/{nixos,darwin}/` (system-level), then add it to
  the relevant `meta/` bundle so machines pick it up.
- **A new machine** → register it in the `machines` set in `flake.nix` and add a
  `modules/machines/<host>/`; it composes the `meta/` bundles plus host specifics.
- **Platform split**: `common/` is cross-platform; `linux/`+`darwin/` hold the
  OS-specific pieces; `meta/` decides which combination a machine gets.


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
nix build .#darwinConfigurations.macbook.systemsudo ./result/sw/bin/darwin-rebuild switch --flake .#macbook
# macOS (nix-darwin) - Work MacBook
nix build .#darwinConfigurations.workmac.systemsudo ./result/sw/bin/darwin-rebuild switch --flake .#workmac
# NixOS (replace <machine> with deadmau5 or dosvec)
nix build .#nixosConfigurations.<machine>.config.system.build.toplevelsudo ./result/bin/switch-to-configuration switch
```

#### Home-Manager Standalone

```bash
# macOS - Personal MacBook
nix build .#homeConfigurations.macbook.activationPackage./result/activate

# macOS - Work MacBook
nix build .#homeConfigurations.workmac.activationPackage./result/activate

# Linux (replace <machine> with deadmau5 or dosvec)
nix build .#homeConfigurations.<machine>.activationPackage./result/activate
```

## Ongoing Usage

After the initial setup, use these consistent commands:

### Using Shell Functions (Recommended)

Once fish shell is configured, use these functions which automatically detect your machine:

```bash
nix-home    # Update home-manager configuration
nix-system  # Update system configuration (darwin-rebuild / nixos-rebuild)
```

### Manual Commands

#### System Configurations

```bash
# macOS (nix-darwin)
sudo darwin-rebuild switch --flake ~/.dotfiles#macbooksudo darwin-rebuild switch --flake ~/.dotfiles#workmac
# NixOS (replace <machine> with deadmau5 or dosvec)
sudo nixos-rebuild switch --flake ~/.dotfiles#<machine>```

#### Home-Manager Standalone

```bash
# macOS
home-manager switch --flake ~/.dotfiles#macbookhome-manager switch --flake ~/.dotfiles#workmac
# Linux (replace <machine> with deadmau5 or dosvec)
home-manager switch --flake ~/.dotfiles#<machine>```

### Docker

```bash
docker build -t dotfiles .
```

## Customization

1. **Personal information**: Edit the `userInfo` and `machineConfig` attribute sets in `flake.nix`
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
