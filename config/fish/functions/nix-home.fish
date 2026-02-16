function nix-home
  set -l flake_config ""
  set -l hostname_val (hostname -s)

  if is_macos
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
  home-manager switch --flake ~/.dotfiles#$flake_config --impure
end
