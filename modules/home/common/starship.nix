{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    starship
    # native jj/git prompt module used by [custom.jj] in starship.toml; reads the
    # jj store directly rather than shelling out to the jj CLI, which keeps the
    # prompt at ~0ms instead of the ~80ms a `jj log` subprocess costs
    jj-starship
  ];

  xdg.configFile = {
    "starship.toml".source = "${sourceRoot}/config/starship.toml";
  };
}
