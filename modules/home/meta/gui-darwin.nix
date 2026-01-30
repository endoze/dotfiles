{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/firefox.nix
    ../common/ghostty.nix
    ../common/databases.nix
    ../darwin/alerter.nix
    ../darwin/karabiner.nix
  ];

  home.packages = with pkgs; [
    nerd-fonts.inconsolata-go
    nerd-fonts.jetbrains-mono
    caffeine
  ];
}
