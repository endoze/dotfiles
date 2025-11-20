{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

let
  githubUser = userConfig.username;
  publicKeysFile = builtins.readFile (pkgs.fetchurl {
    url = "https://github.com/${githubUser}.keys";
    # sha256 = "1VwDw+Z6+WeWyPrpFE8C8KiR9Iq+GZfH29SgjPZyWC0=";
    sha256 = "uchnIjzaC7KYW9VzKp01EcMG7d+eG+HyGdrQrzNS+44=";
  });
  publicKeys = lib.splitString "\n" (lib.removeSuffix "\n" publicKeysFile);
in
{
  imports = [
    ./hardware-configuration.nix
    ../../system/meta/cli-nixos.nix
    ../../system/meta/gui-nixos.nix
  ];

  services.dnsmasq-resolver.enable = true;

  networking.hostName = systemConfig.hostName or "deadmau5";

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users."${userConfig.username}" = {
    extraGroups = [ "pipewire" ];
    openssh.authorizedKeys.keys = publicKeys;
  };

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    download-buffer-size = 524288000;
  };

  environment.sessionVariables = {
    XDG_RUNTIME_DIR = "/run/user/1000";
    XDG_PICTURES_DIR = "${userConfig.homeDirectory}/Pictures";
    HYPRSHOT_DIR = "${userConfig.homeDirectory}/Pictures/screenshots";
    NIXOS_OZONE_WL = "1";
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      vim = "nvim";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05";
}
