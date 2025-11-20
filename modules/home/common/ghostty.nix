{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  xdg.configFile = {
    "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/ghostty";
  };
}
