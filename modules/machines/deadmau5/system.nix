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
    ../../os/nixos/bluetooth.nix
    ../../os/nixos/docker.nix
    ../../os/nixos/hyprland.nix
    ../../os/nixos/nvidia.nix
    ../../os/nixos/pipewire.nix
    ../../os/nixos/steam.nix
  ];

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
    # GDK_FONT_SCALE = "1.5";
    # GDK_SCALE = "1.5";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    # CLI
    curl
    fish
    git
    killall
    neovim
    wget

    # System tools
    lsb-release
    pciutils
    usbutils

    # GUI
    (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
    (pkgs.callPackage ../../sddm-theme.nix { })
    cliphist
    adwaita-icon-theme
    file-roller
    kdePackages.gwenview
    hyprpaper
    hyprshot
    kitty
    nwg-look
    obs-studio
    qt5.qtwayland
    qt6.qtwayland
    qt6.qt5compat
    qt6.qtdeclarative
    rofi
    slack
    swaynotificationcenter
    waybar
    wl-clipboard

    protontricks
  ];

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };
    fish = {
      enable = true;
      shellAliases = {
        vim = "nvim";
      };
    };

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    xfconf.enable = true;

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Standard C/C++ libraries
        stdenv.cc.cc.lib
        zlib

        # Libraries for lua (including development headers)
        readline.dev
        readline
        ncurses.dev
        ncurses

        # Dotnet and OmniSharp dependencies
        icu
        openssl
        krb5
        curl
      ];
    };
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };

  services.openssh.enable = true;
  services.flatpak.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05";
}
