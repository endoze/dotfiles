{ config, pkgs, lib, ... }:

{
  # Enable the Tailscale service
  services.tailscale = {
    enable = true;

    # Use the netfilter (iptables) implementation instead of userspace networking
    # This provides better performance and allows Tailscale to work as an exit node
    # "server" = advertise routes/exit node, "client" = accept routes, "both" = both
    useRoutingFeatures = lib.mkDefault "client";

    # Open the firewall for Tailscale
    openFirewall = true;
  };

  # Add tailscale package to system packages for CLI access
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Ensure Tailscale starts after network is online
  systemd.services.tailscaled = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
