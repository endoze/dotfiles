{ config, pkgs, lib, userConfig, ... }:

{
  boot.isContainer = true;

  networking.hostName = userConfig.hostName;

  time.timeZone = "America/New_York";

  users.users.${userConfig.username} = {
    isNormalUser = true;
    home = userConfig.homeDirectory;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    uid = 1000;
  };

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" userConfig.username ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
