{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  xdg.configFile = {
    "karabiner".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/karabiner";
  };
}
