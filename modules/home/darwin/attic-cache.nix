{ config, pkgs, lib, ... }:

let
  substituterUrl = "https://cache.kahdu.org/main";
  publicKey = "main:ch1Il2WBscgvKTDg00wIqQCT/wSyqlA7lD0n2m2VkOg=";
  # Must match sops.templates."user-nix-netrc".path in
  # modules/system/darwin/attic-cache.nix. This is the user-readable copy;
  # the daemon uses a separate root-owned copy at /etc/nix/netrc.
  netrcPath = "${config.home.homeDirectory}/.config/nix/netrc";
in
{
  # Drops ~/.config/nix/nix.conf to add the kahdu Attic cache as a substituter.
  # Determinate Nix reads this in addition to /etc/nix/nix.conf and
  # /etc/nix/nix.custom.conf - all merge. Requires this user to be in
  # `trusted-users` (Determinate's installer adds the installing user by
  # default; check with `nix show-config | grep '^trusted-users'`).
  xdg.configFile."nix/nix.conf".text = ''
    extra-substituters = ${substituterUrl}
    extra-trusted-public-keys = ${publicKey}
    netrc-file = ${netrcPath}
  '';
}
