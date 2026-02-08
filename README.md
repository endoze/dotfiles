# Nix Dotfiles Configuration

This repository contains a multi-platform Nix configuration supporting:
- macOS (ARM/Intel)
- Linux (NixOS)

## Available Configurations

### Home Manager Configurations
- `linux` - Linux desktop configuration
- `macbook` - Personal MacBook configuration
- `work-macbook` - Work MacBook configuration

### Darwin (macOS) System Configurations
- `macbook` - Personal MacBook system configuration
- `work-macbook` - Work MacBook system configuration

### NixOS System Configurations
- `linux-desktop` - Linux desktop system configuration

## Structure

```
.
├── flake.nix              # Main flake configuration
├── flake.lock             # Locked flake dependencies
├── modules/               # All configuration modules
│   ├── home/              # Home-manager configurations
│   │   ├── default.nix    # Common home configuration
│   │   ├── darwin.nix     # macOS-specific home config
│   │   └── linux.nix      # Linux-specific home config
│   ├── machines/          # Machine-specific configurations
│   │   ├── macbook/       # MacBook configurations
│   │   └── linux-desktop/ # Linux desktop configurations
│   ├── os/                # Operating system configurations
│   │   ├── darwin.nix     # macOS system config
│   │   └── nixos.nix      # NixOS system config
│   ├── users.nix          # User and machine definitions
│   ├── users.local.nix    # Local user config (git-ignored)
│   ├── users.example.nix  # Template for local config
│   ├── bat.nix            # Bat (cat alternative) config
│   ├── fish.nix           # Fish shell config
│   ├── ghostty.nix        # Ghostty terminal config
│   ├── git.nix            # Git config
│   ├── lsd.nix            # lsd (ls alternative) config
│   ├── neovim.nix         # Neovim config
│   ├── python.nix         # Python environment
│   ├── ruby.nix           # Ruby environment
│   ├── selene.nix         # Selene Lua linter
│   ├── shell-ai.nix       # Shell AI tool
│   ├── starship.nix       # Starship prompt config
│   └── tmux.nix           # Tmux config
└── config/                # Actual configuration files
    ├── fish/              # Fish shell configurations
    ├── nvim/              # Neovim configurations
    ├── tmux/              # Tmux configurations
    └── ...                # Other tool configs
```

## Local Configuration (for Personal Info)

To keep personal information out of this public repository, configurations can use a local configuration file that is not committed to git. The configuration dynamically reads from your local file when using the `--impure` flag.

### Setup

1. Copy the example configuration:
   ```bash
   cp modules/users.example.nix modules/users.local.nix
   ```

2. Edit `modules/users.local.nix` with your actual information:
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
   home-manager switch --flake .#work-macbook --impure
   home-manager switch --flake .#linux --impure

   # Or use the provided fish shell functions (already include --impure)
   nix-home    # for home-manager
   nix-system  # for darwin-rebuild
   ```

### How it Works

- The `modules/users.nix` file checks for `modules/users.local.nix` at runtime
- When running with `--impure`, it reads from `$HOME/.dotfiles/modules/users.local.nix`
- If the local file doesn't exist, it falls back to generic placeholders
- The local file is git-ignored and will never be committed to the repository
- Each machine uses the same local config file - just one set of values for all configurations

### Important Notes

- **Always use the `--impure` flag** when switching configurations that use local config
- For configurations using local config, your actual username and hostname are read from the local config file, not the flake attribute name

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
nix build .#darwinConfigurations.work-macbook.system --impure
sudo ./result/sw/bin/darwin-rebuild switch --flake .#work-macbook --impure

# NixOS - Linux Desktop
nix build .#nixosConfigurations.linux-desktop.config.system.build.toplevel
sudo ./result/bin/switch-to-configuration switch
```

#### Home-Manager Standalone

```bash
# macOS - Personal MacBook
nix build .#homeConfigurations.macbook.activationPackage --impure
./result/activate

# macOS - Work MacBook
nix build .#homeConfigurations.work-macbook.activationPackage --impure
./result/activate

# Linux
nix build .#homeConfigurations.linux.activationPackage --impure
./result/activate
```

## Ongoing Usage

After the initial setup, use these consistent commands:

### Using Shell Functions (Recommended)

Once fish shell is configured, use these simple functions:

```bash
nix-home    # Update home-manager configuration
nix-system  # Update system configuration (darwin/NixOS)
```

These functions automatically:
- Use the correct configuration for your machine
- Include `--impure` flag when needed for local configs
- Work consistently across platforms

### Manual Commands

#### System Configurations

```bash
# macOS (nix-darwin) - Personal MacBook
sudo darwin-rebuild switch --flake ~/.dotfiles#macbook --impure

# macOS (nix-darwin) - Work MacBook
sudo darwin-rebuild switch --flake ~/.dotfiles#work-macbook --impure

# NixOS - Linux Desktop
sudo nixos-rebuild switch --flake ~/.dotfiles#linux-desktop --impure
```

#### Home-Manager Standalone

```bash
# macOS - Personal MacBook
home-manager switch --flake ~/.dotfiles#macbook --impure

# macOS - Work MacBook
home-manager switch --flake ~/.dotfiles#work-macbook --impure

# Linux
home-manager switch --flake ~/.dotfiles#linux --impure
```

## Customization

1. **Personal/Work user information**: Create `modules/users.local.nix` from the example template (see Local Configuration section above)
2. **Add new packages**: Edit the relevant `home.packages` in `modules/home/default.nix` or machine-specific files
3. **Add new modules**: Create a new module in `modules/` and import it in `modules/home/default.nix`
4. **Machine-specific settings**: Edit files in `modules/machines/your-machine/`
5. **New machines**: Add new machine configurations to `flake.nix` and create corresponding files in `modules/machines/`

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

## Adding a New Machine

1. Create a new directory: `machines/new-machine/`
2. Add `home.nix` and/or `system.nix` as needed
3. Update `flake.nix` to include the new configuration
4. Build and switch to the new configuration
