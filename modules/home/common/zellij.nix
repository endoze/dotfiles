{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile = {
    "zellij".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/zellij";
  };
}
