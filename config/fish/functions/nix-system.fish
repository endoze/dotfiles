function nix-system
  set -l flake_config ""
  set -l rebuild_cmd ""
  set -l hostname_val (hostname -s)

  if is_macos
    set rebuild_cmd "darwin-rebuild"
    # Map hostname to flake configuration
    switch $hostname_val
      case macbook-m3
        set flake_config "macbook"
      case workmac
        set flake_config "workmac"
      case '*'
        echo "Unknown macOS hostname: $hostname_val"
        return 1
    end
  else if is_linux
    set flake_config "linux-desktop"
    set rebuild_cmd "nixos-rebuild"
  else
    echo "Unknown system type: "(uname -s)

    return 1
  end

  echo "Using configuration: $flake_config"
  sudo $rebuild_cmd switch --flake ~/.dotfiles#$flake_config --impure
end
