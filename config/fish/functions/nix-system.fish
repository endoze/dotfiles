function nix-system
  set -l flake_config ""
  set -l rebuild_cmd ""

  if is_macos
    set flake_config "macbook"
    set rebuild_cmd "darwin-rebuild"
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
