{ config, pkgs, lib, inputs, userConfig, ... }:

{
  services.shirase.enable = true;

  xdg.configFile = {
    "shirase".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/shirase";
  };
}
