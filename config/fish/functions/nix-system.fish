function nix-system
  set -l flake_config ""
  set -l rebuild_cmd ""
  set -l hostname_val (hostname -s)

  if is_macos
    set rebuild_cmd "darwin-rebuild"
    # Map hostname to flake configuration
    switch $hostname_val
      case macbook
        set flake_config "macbook"
      case workmac
        set flake_config "workmac"
      case '*'
        echo "Unknown macOS hostname: $hostname_val"
        return 1
    end
  else if is_linux
    set rebuild_cmd "nixos-rebuild"
    switch $hostname_val
      case deadmau5
        set flake_config "deadmau5"
      case dosvec
        set flake_config "dosvec"
      case '*'
        echo "Unknown Linux hostname: $hostname_val"
        return 1
    end
  else
    echo "Unknown system type: "(uname -s)

    return 1
  end

  echo "Using configuration: $flake_config"

  if is_linux
    # Evaluate/fetch as the invoking user so private flake inputs (e.g.
    # monban over git+ssh) authenticate with our SSH agent, then elevate
    # only for activation. Wrapping the whole rebuild in sudo fetches as
    # root -- which has no SSH agent -> "Permission denied (publickey)".
    $rebuild_cmd switch --flake ~/.dotfiles#$flake_config --sudo
  else
    sudo $rebuild_cmd switch --flake ~/.dotfiles#$flake_config
  end
end
