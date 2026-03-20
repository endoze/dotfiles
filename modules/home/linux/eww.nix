{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    eww
    jq
    socat
  ];

  xdg.configFile = {
    "eww".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/eww";
  };
}
