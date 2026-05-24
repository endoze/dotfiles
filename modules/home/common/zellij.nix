{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    zellij
  ];

  home.file = {
    ".local/bin/claude-status".source = "${sourceRoot}/bin/claude-status";
  };

  xdg.configFile = {
    "zellij".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/zellij";
  };
}
