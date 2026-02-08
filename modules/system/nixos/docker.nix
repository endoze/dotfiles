{ config, pkgs, lib, userConfig, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Allow Docker containers to communicate with host services
  networking.firewall.trustedInterfaces = [ "docker0" ];

  users.users.${userConfig.username}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}