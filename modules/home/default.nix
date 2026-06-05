{ config, pkgs, lib, userConfig, sourceRoot, systemConfig, ... }:

{
  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;
    stateVersion = "26.05";
  };

  home.file = {
    ".rustfmt.toml".source = "${sourceRoot}/config/rustfmt.toml";
  };

  programs = {
    home-manager.enable = true;

    gpg = {
      enable = true;
      settings = {
        use-agent = true;
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  news.display = "silent";
}
