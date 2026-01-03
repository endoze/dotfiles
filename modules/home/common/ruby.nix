{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [ ];

  home.file = {
    ".gemrc".source = "${sourceRoot}/config/gemrc";
    ".irbrc".source = "${sourceRoot}/config/irbrc";
    ".pryrc".source = "${sourceRoot}/config/pryrc";
    ".rubocop.yml".source = "${sourceRoot}/config/rubocop.yml";
    ".bundle/config".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/bundle/config";
  };
}
