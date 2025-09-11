{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    colima
    tableplus
    trash-cli
  ];
}
