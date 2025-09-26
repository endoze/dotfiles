{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  xdg.configFile = {
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/hypr";
  };
}