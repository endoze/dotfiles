# archimedes - NixOS router configuration
# 4-port 2.5GbE Intel PCIe NIC (igc driver): 1 WAN + 3 LAN bridged
# Management access via onboard eth0 (192.168.1.99)
#
# TODOs before going live (NIC not yet arrived):
#   eth0/eth1/eth2/eth3 - replace with real PCIe NIC interface names
#   192.168.1.x         - replace with dosvec's actual LAN IP (pihole)
{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, sourceRoot, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system/meta/cli-nixos.nix
    ../../system/nixos/tailscale.nix
    ../../system/nixos/nix-ld.nix
    ../../system/nixos/attic-cache.nix
  ];

  # ==========================================================================
  # sops-nix secrets configuration
  # ==========================================================================
  sops = {
    age.keyFile = "/home/${userConfig.username}/.config/sops/age/keys.txt";
    defaultSopsFile = sourceRoot + "/secrets/archimedes.enc.yaml";
    secrets = {
      "tailscale-authkey" = { };
      "attic-admin-key" = {
        sopsFile = sourceRoot + "/secrets/shared.enc.yaml";
      };
    };
  };

  networking.hostName = "archimedes";

  # Disable NetworkManager — router needs declarative interface control.
  # NM conflicts with bridge members and networking.nat.
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = false;

  # Management interface: onboard NIC, keeps SSH reachable at 192.168.1.99
  networking.interfaces."eth0".useDHCP = true;

  # LAN bridge, WAN, and NAT — commented out until PCIe NIC arrives
  # networking.bridges."br-lan".interfaces = [ "REPLACE_LAN1" "REPLACE_LAN2" "REPLACE_LAN3" ];
  # networking.interfaces."br-lan" = {
  #   ipv4.addresses = [{ address = "192.168.1.1"; prefixLength = 24; }];
  # };
  # networking.interfaces."REPLACE_WAN".useDHCP = true;
  # networking.nat = {
  #   enable = true;
  #   externalInterface = "REPLACE_WAN";
  #   internalInterfaces = [ "br-lan" ];
  # };

  # IP forwarding and router-appropriate kernel params
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 2; # loose — needed with multiple interfaces
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.netfilter.nf_conntrack_max" = 131072;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # DNS forwarding + DHCP — disabled until PCIe NIC is installed
  # services.dnsmasq = {
  #   enable = true;
  #   settings = {
  #     interface = "br-lan";
  #     bind-interfaces = true;
  #     no-resolv = true;
  #     server = [ "192.168.1.144" "127.0.0.1#5053" ];
  #     dhcp-range = "192.168.1.100,192.168.1.200,24h";
  #     dhcp-option = [
  #       "option:router,192.168.1.1"
  #       "option:dns-server,192.168.1.1"
  #     ];
  #   };
  # };

  # DoH proxy — disabled until PCIe NIC is installed
  # services.dnscrypt-proxy2 = {
  #   enable = true;
  #   settings = {
  #     listen_addresses = [ "127.0.0.1:5053" ];
  #     server_names = [ "cloudflare" ];
  #   };
  # };

  # Tailscale in server mode — advertises LAN subnet for remote access
  services.tailscale = {
    useRoutingFeatures = "server";
    authKeyFile = config.sops.secrets."tailscale-authkey".path;
    extraUpFlags = [
      "--exit-node="
      "--accept-routes=false"
      "--accept-dns=false"
      "--advertise-exit-node"
      "--advertise-routes=192.168.1.0/24"
    ];
  };

  systemd.services.tailscaled-autoconnect = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  # Fix Tailscale UDP GRO forwarding warning on management interface
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth0", RUN+="${pkgs.ethtool}/bin/ethtool -K eth0 rx-udp-gro-forwarding on rx-gro-list off"
  '';

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH reachable from WAN/management
    trustedInterfaces = [ "br-lan" "tailscale0" ];
  };

  # sshguard: whitelist management LAN and future router LAN
  services.sshguard.whitelist = lib.mkForce [
    "127.0.0.0/8"
    "100.64.0.0/10" # Tailscale
    "192.168.1.0/24" # management LAN (enp3s0)
    "192.168.1.0/24" # LAN
  ];

  # Disable desktop-oriented services pulled in by default.nix
  services.printing.enable = lib.mkForce false;
  services.pipewire.enable = lib.mkForce false;

  users.users."${userConfig.username}" = {
    extraGroups = [ "wheel" ];
  };

  security.sudo.extraRules = [
    {
      users = [ userConfig.username ];
      commands = [
        { command = "ALL"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
