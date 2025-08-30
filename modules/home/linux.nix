{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Linux specific tools
    xclip
    xsel

    # System tools
    lsb-release
    pciutils
    usbutils

    gnumake
  ];

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gtk2;
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
