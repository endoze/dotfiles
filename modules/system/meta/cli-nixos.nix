{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    fish
    git
    htop
    killall
    lazyjournal
    neovim
    ntfs3g
    vim
    wget
    lsb-release
    pciutils
    usbutils
  ];
}
