{ config, pkgs, lib, ... }:

{
  # Machine-specific home configuration for Linux desktop
  home.packages = with pkgs; [ ];

  services = {
    redshift = {
      enable = true;
      latitude = 40.0;
      longitude = -74.0;
      temperature = {
        day = 6500;
        night = 4500;
      };
    };
  };

  home.sessionVariables = {
    DEVELOPMENT_MACHINE = "linux-desktop";
  };
}
