{ config, pkgs, lib, ... }:

{
  imports = [
    ./linux/default.nix
  ];

  home.packages = with pkgs; [
    clang-tools
    cmake
    fastfetch
    gcc
    ghostty
    gnumake
    less
    lua
    luarocks
    montserrat
    ncdu
    nodejs
    usbutils
  ];


  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = false;
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
