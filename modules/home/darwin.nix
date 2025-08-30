{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Development
    colima

    # Utilities
    trash-cli
  ];
}
