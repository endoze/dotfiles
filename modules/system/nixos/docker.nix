{ config, pkgs, lib, userConfig, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };

    # Preserve the pre-24.11 NixOS default: keep running containers alive
    # across docker daemon restarts. NixOS flipped this default to upstream's
    # `false` at stateVersion 24.11; pin it so bumping stateVersion doesn't
    # change daemon-restart behavior.
    daemon.settings.live-restore = true;
  };

  # Allow Docker containers to communicate with host services
  networking.firewall.trustedInterfaces = [ "docker0" ];

  users.users.${userConfig.username}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
