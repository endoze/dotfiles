# Basic pipewire configuration without device-specific virtual sinks/sources
{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    helvum
  ];

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    systemWide = false;

    alsa.enable = true;
    alsa.support32Bit = true;
    audio.enable = true;
    pulse.enable = true;

    extraConfig.pipewire."08-default-rates" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 ];
      };
    };

    wireplumber = {
      enable = true;
      package = pkgs.wireplumber;
    };
  };
}
