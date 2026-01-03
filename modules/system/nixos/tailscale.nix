{ config, pkgs, lib, ... }:

{
  # Enable the Tailscale service
  services.tailscale = {
    enable = true;

    # Use the netfilter (iptables) implementation instead of userspace networking
    # This provides better performance and allows Tailscale to work as an exit node
    # "server" = advertise routes/exit node, "client" = accept routes, "both" = both
    useRoutingFeatures = "server";

    # Open the firewall for Tailscale
    openFirewall = true;

    # Extra flags to pass to tailscale up
    extraUpFlags = [
      "--exit-node="
      "--accept-routes=false"
      "--advertise-exit-node"
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
