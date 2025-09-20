function nix-home
  set -l flake_config ""

  if is_macos
    set flake_config "macbook"
  else if is_linux
    set flake_config "endoze@linux"
  else
    echo "Unknown system type: "(uname -s)

    return 1
  end

  echo "Using configuration: $flake_config"
  home-manager switch --flake ~/.dotfiles#$flake_config --impure
end
