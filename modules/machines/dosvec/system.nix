# dosvec - Headless NixOS server configuration
# Home server with k3s, NVIDIA GPU, and Coral TPU
# NVMe root with ZFS storage pool on separate disks
{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, sourceRoot, ... }:

let
  githubUser = userConfig.username;
  publicKeysFile = builtins.readFile (pkgs.fetchurl {
    url = "https://github.com/${githubUser}.keys";
    # sha256 = "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
    sha256 = "6KWN+v3skxU1/h0aJBtE/Opli22VFIsv+Z/f3P7oCgs=";
  });
  publicKeys = lib.splitString "\n" (lib.removeSuffix "\n" publicKeysFile);
in
{
  imports = [
    ./hardware-configuration.nix
    ./zfs-datasets.nix                   # ZFS dataset properties and migration tools
    ../../system/meta/cli-nixos.nix      # CLI tools only (no GUI)
    ../../system/nixos/zfs.nix           # ZFS pool management
    ../../system/nixos/k3s.nix           # k3s Kubernetes
    ../../system/nixos/nvidia-headless.nix  # NVIDIA without GUI
    ../../system/nixos/coral-tpu.nix     # Google Coral TPU
    ../../system/nixos/tailscale.nix     # VPN as system service
    ../../system/nixos/r8125.nix        # Realtek R8125 2.5GbE driver
  ];

  # ==========================================================================
  # sops-nix secrets configuration
  # ==========================================================================
  sops = {
    # Age key location (must exist on the machine)
    age.keyFile = "/home/${userConfig.username}/.config/sops/age/keys.txt";

    # Default encrypted secrets file for this machine
    defaultSopsFile = sourceRoot + "/secrets/dosvec.enc.yaml";

    # Secrets to decrypt (available at /run/secrets/<name>)
    secrets = {
      "tailscale-authkey" = { };
    };
  };

  # Tailscale server configuration (dosvec-specific)
  services.tailscale = {
    useRoutingFeatures = "server";
    authKeyFile = config.sops.secrets."tailscale-authkey".path;
    extraUpFlags = [
      "--exit-node="
      "--accept-routes=false"
      "--accept-dns=false"             # Prevent DNS conflict with Pi-hole
      "--advertise-exit-node"
      "--advertise-routes=192.168.1.0/24"
      "--advertise-tags=tag:container"  # Required for legacy ACLs
    ];
  };
  # Ensure sops secrets are decrypted before tailscale tries to use the auth key
  systemd.services.tailscaled-autoconnect = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  # Required for ZFS - must be unique 8 hex characters
  # This is the actual hostId from dosvec (from /etc/machine-id)
  networking.hostId = "3b586205";

  # Always use "dosvec" as hostname for this server
  networking.hostName = "dosvec";

  # Headless server - no display manager or desktop
  services.xserver.enable = false;

  # Time and locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # User configuration
  users.users."${userConfig.username}" = {
    openssh.authorizedKeys.keys = publicKeys;
    extraGroups = [ "wheel" "docker" "coral" ];
  };

  # Temporary passwordless sudo for initial setup
  security.sudo.extraRules = [
    {
      users = [ userConfig.username ];
      commands = [
        { command = "ALL"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  # Firewall configuration
  networking.firewall = {
    enable = true;

    # Always allowed ports
    allowedTCPPorts = [
      22      # SSH
      53      # Pi-hole DNS
      80      # HTTP
      443     # HTTPS
      6443    # k3s API (also in k3s.nix, but explicit here)
      6697    # Soju IRC
      8554    # Frigate RTSP
      8555    # Frigate WebRTC
      32400   # Plex
      58946   # Deluge torrent
    ];

    allowedUDPPorts = [
      53      # Pi-hole DNS
      8555    # Frigate WebRTC
      15636   # Enshrouded game
      15637   # Enshrouded query
      58946   # Deluge torrent
    ];
  };

  # Enable fish shell
  programs.fish = {
    enable = true;
    shellAliases = {
      vim = "nvim";
      k = "kubectl";
      kgp = "kubectl get pods";
      kga = "kubectl get all";
      kgn = "kubectl get nodes";
    };
  };

  # Dynamic library shim for running unpatched binaries
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      readline.dev
      readline
      ncurses.dev
      ncurses
      icu
      openssl
      krb5
      curl
    ];
  };

  # Server-specific packages
  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
    btop
    iotop
    nethogs

    # Network tools
    iperf3
    nmap
    tcpdump

    # Container/k8s debugging
    dive        # Docker image explorer
    cri-tools   # CRI debugging tool (provides crictl)
  ];

  # Set NVMe I/O scheduler to none (NVMe has internal scheduling, software scheduler adds CPU overhead)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # Periodic TRIM for NVMe longevity (lower overhead than continuous discard)
  services.fstrim.enable = true;

  # Distribute hardware interrupts across cores
  services.irqbalance.enable = true;

  boot.kernel.sysctl = {
    # VM tuning
    "vm.vfs_cache_pressure" = 50;            # Hold filesystem metadata in memory longer (benefits ZFS/k3s)
    "vm.min_free_kbytes" = 131072;           # 128 MB free minimum (prevents allocation stalls during GPU ops)

    # Network tuning (k3s pods, Plex, Tailscale, Frigate streams)
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_tw_reuse" = 1;
  };

  # Disable suspend/hibernate - server should always be on
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  # Enable automatic upgrades (optional, can be disabled)
  # system.autoUpgrade = {
  #   enable = true;
  #   flake = "github:Endoze/dotfiles#dosvec";
  #   dates = "04:00";
  #   allowReboot = false;
  # };

  system.stateVersion = "24.05";
}
