{ config, pkgs, lib, userConfig, ... }:

{
  home.packages = with pkgs; [
    mise
  ];

  # Link mise configuration with out-of-store symlink for live updates
  xdg.configFile."mise".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/mise";
}
