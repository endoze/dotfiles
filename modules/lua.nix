{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.file = {
    ".stylua.toml".source = "${sourceRoot}/config/lua/stylua.toml";
  };
}