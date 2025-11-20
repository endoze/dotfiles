{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [ ];

  home.file = {
    ".gemrc".source = "${sourceRoot}/config/gemrc";
    ".irbrc".source = "${sourceRoot}/config/irbrc";
    ".pryrc".source = "${sourceRoot}/config/pryrc";
    ".rubocop.yml".source = "${sourceRoot}/config/rubocop.yml";
    ".bundle/config".source = "${sourceRoot}/config/bundle/config";
  };
}
