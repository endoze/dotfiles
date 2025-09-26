fish_add_path -m ~/.local/bin
fish_add_path -m /nix/var/nix/profiles/default/bin
fish_add_path -m /run/current-system/sw/bin
fish_add_path -m ~/.nix-profile/bin # this has to take priority

# On NixOS, wrappers must come first for setuid binaries
if test -d /run/wrappers/bin
    fish_add_path -m /run/wrappers/bin
end
