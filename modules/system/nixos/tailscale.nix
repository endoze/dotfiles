{ config, pkgs, lib, ... }:

{
  # Enable the Tailscale service
  services.tailscale = {
    enable = true;

    # Use the netfilter (iptables) implementation instead of userspace networking
    # This provides better performance and allows Tailscale to work as an exit node
    useRoutingFeatures = "both";

    # Open the firewall for Tailscale
    openFirewall = true;

    # Extra flags to pass to tailscale up
    extraUpFlags = [
      "--accept-routes"
      # Uncomment to advertise this machine as an exit node:
      "--advertise-exit-node"
      # Uncomment to advertise subnet routes (example):
      "--advertise-routes=192.168.1.0/24"
    ];
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
