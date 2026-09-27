{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, sourceRoot, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system/meta/cli-nixos.nix
    ../../system/meta/gui-nixos.nix
    # Machine-specific: nvidia GPU and custom pipewire config
    ../../system/nixos/nvidia.nix
    ../../system/nixos/pipewire.nix
    ../../system/nixos/attic-cache.nix
    ../../system/nixos/plymouth.nix
    ../../system/nixos/waydroid-nvidia.nix
  ];

  sops = {
    age.keyFile = "/home/${userConfig.username}/.config/sops/age/keys.txt";
    defaultSopsFile = sourceRoot + "/secrets/shared.enc.yaml";
    secrets."attic-admin-key" = { };
  };

  # Use nvidia driver for Xorg/Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  services.dnsmasq-resolver.enable = true;

  # dnsmasq is resolved's global DNS, so it fields every name that isn't .test
  # or *.ts.net. Point it at explicit upstreams rather than letting it follow
  # /etc/dnsmasq-resolv.conf, which just mirrors whatever DHCP handed out.
  # no-resolv overrides the resolv-file= the nixpkgs module always emits.
  services.dnsmasq.settings = {
    no-resolv = true;
    server = [ "1.1.1.1" "1.0.0.1" ];
  };

  # Route every name to the global DNS (dnsmasq) rather than letting enp3s0's
  # DHCP servers win on their plain default route. In resolved an explicit
  # route-domain match outranks a default route, so tailscale0's "~ts.net"
  # still takes *.ts.net. Subsumes the "~test" that dnsmasq.nix sets, since
  # dnsmasq answers .test from address=/.test/ either way.
  #
  # Not networking.networkmanager.connectionConfig."ipv4.ignore-auto-dns":
  # ignore-auto-dns is not one of the properties NM accepts as a [connection]
  # default (see NetworkManager.conf(5)), so NM silently discards it.
  services.resolved.settings.Resolve.Domains = lib.mkForce "~.";

  # A buggy client flooded sshd here: MaxStartups throttled at the 10:30:100
  # default and dropped hundreds of connections, and the sessions it did accept
  # sat ESTABLISHED for hours because nothing probed them. ClientAlive* makes
  # sshd reap a silent peer after 90s (30s x 3 probes); the wider MaxStartups
  # gives a burst room to land before random early drop kicks in.
  services.openssh.settings = {
    ClientAliveInterval = 30;
    ClientAliveCountMax = 3;
    MaxStartups = "30:50:200";
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # chiaki-ng (PlayStation Remote Play) LAN console discovery.
  #
  # chiaki binds its discovery socket to the first free port in 9303-9319
  # (lib/include/chiaki/discovery.h) and probes for consoles by sending to the
  # subnet broadcast address and 255.255.255.255 on UDP 9302 (PS5) / 987 (PS4).
  # The console answers *unicast* from its own address, which does not match the
  # conntrack reply tuple created for the broadcast, so the reply arrives as
  # NEW. There is no conntrack helper for port 9302 (this is the same problem
  # nf_conntrack_netbios_ns exists to solve for NetBIOS), so without this rule
  # nixos-fw drops the reply and the console never appears in chiaki's list.
  #
  # The port-accept rules in nixos-fw carry no ctstate match, so this accepts
  # the NEW-state reply on its own merits. Streaming itself is all outbound
  # (9295 TCP/UDP, 9296-9297 UDP to the console) and needs no rule, which is
  # why registering a console by IP works without this.
  networking.firewall.allowedUDPPortRanges = [
    { from = 9303; to = 9319; }
  ];

  # Allow input group to create virtual input devices (for Sunshine gamepad/keyboard/mouse)
  # Set NVMe I/O scheduler to none (NVMe has internal scheduling, software scheduler adds CPU overhead)
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # Ensure Sunshine starts after graphical session and the eww systray watcher
  # (modules/home/linux/eww.nix) is up; otherwise Sunshine can race for the SNI
  # watcher name and break the tray.
  systemd.user.services.sunshine = {
    after = [ "graphical-session.target" "eww.service" ];
    # wants (not requires) for eww: order after the tray without letting an eww
    # flap cascade-stop sunshine via Requires= stop-propagation.
    wants = [ "graphical-session.target" "eww.service" ];
    serviceConfig.Restart = "on-failure";
  };

  # Tailscale as exit node and route advertiser for remote LAN access.
  # extraSetFlags, not extraUpFlags: extraUpFlags needs authKeyFile, which this host lacks.
  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--exit-node="
      "--accept-routes=false"
      "--advertise-exit-node"
      "--advertise-routes=10.0.0.0/24" # this host's LAN; 192.168.1.0/24 is dosvec's
    ];
  };

  networking.hostName = systemConfig.hostName or "deadmau5";

  # Wifi-only host: wait-online blocks graphical.target for up to 60s on slow association
  systemd.services.NetworkManager-wait-online.enable = false;

  # Without wait-online, attic starts pre-association and fails on DNS until wifi is up
  systemd.services.attic-watch-store = {
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig.RestartSec = lib.mkForce "30s";
  };

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

  users.users."${userConfig.username}" = {
    extraGroups = [ "pipewire" "input" "kvm" ];
  };


  # CachyOS latest kernel (7.0) with BORE scheduler for better desktop/gaming performance
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelParams = [
    "mitigations=off" # ~5-15% perf gain on Intel (disables Spectre/Meltdown mitigations)
    "split_lock_detect=off" # Prevents severe perf penalty in some Proton games (God of War, etc.)
    "transparent_hugepage=madvise" # THP only for apps that request it (Proton/CUDA do, avoids overhead for others)
    "threadirqs" # Move IRQ handlers to schedulable kernel threads
    "nowatchdog" # Disable watchdog timers (reduces interrupts)
    "nmi_watchdog=0" # Disable NMI watchdog
    "quiet"
    "loglevel=3"
    "nvidia_drm.fbdev=1"
  ];

  boot.extraModprobeConfig = ''
    options nvidia NVreg_UsePageAttributeTable=1
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
    options nvidia NVreg_TemporaryFilePath=/var/tmp
  '';

  boot.kernel.sysctl = {
    # VM tuning
    "vm.swappiness" = 150; # With zram: prefer compressing into zram over evicting file cache
    "vm.vfs_cache_pressure" = 50; # Hold filesystem metadata in memory longer
    "vm.dirty_bytes" = 268435456; # 256 MB dirty limit before synchronous writeback
    "vm.dirty_background_bytes" = 134217728; # 128 MB before background writeback starts
    "vm.dirty_writeback_centisecs" = 1000; # Flush every 10s instead of 5s
    "vm.dirty_expire_centisecs" = 1000;
    "vm.compaction_proactiveness" = 0; # Disable proactive compaction (reduces background CPU)
    "vm.watermark_boost_factor" = 1; # Less aggressive page reclaim
    "vm.min_free_kbytes" = 131072; # 128 MB free minimum (prevents allocation stalls during CUDA ops)
    "vm.overcommit_memory" = 1; # Allow overcommit (important for Ollama/Proton)
    "vm.page_lock_unfairness" = 1; # Reduce lock contention
    "vm.page-cluster" = 0; # Disable swap readahead (NVMe is fast enough)

    # Kernel
    "kernel.split_lock_mitigate" = 0; # Belt and suspenders with boot param
    "kernel.printk" = "3 3 3 3"; # Reduce printk overhead

    # Network (Ollama serving, Sunshine streaming)
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_tw_reuse" = 1;
  };

  # CPU frequency governor - always max clocks, no ramp-up latency
  powerManagement.cpuFreqGovernor = "performance";

  # scx_lavd scheduler - designed for gaming/latency-critical workloads
  # Falls back to BORE if it exits. Used by Meta in production.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--performance" ];
  };

  # zram compressed swap - safety net for LLM workloads and heavy gaming
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    priority = 100;
  };

  # Mount Windows C: drive
  fileSystems."/home/${userConfig.username}/Windows" = {
    device = "/dev/disk/by-uuid/8226F72326F716BF";
    fsType = "ntfs3";
    options = [
      "uid=1000"
      "gid=100"
      "umask=022"
      "nofail"
      "x-systemd.automount"
    ];
  };

  # 2TB ext4 storage drive into home folder (migrated off NTFS 2026-07-13)
  fileSystems."/home/${userConfig.username}/Storage2" = {
    device = "/dev/disk/by-uuid/b58c9f46-64a8-435c-8252-bf038b82dcc6";
    fsType = "ext4";
    options = [
      "nofail" # Boot succeeds even if drive is absent
      "x-systemd.automount" # Mount on first access, not at boot
      "noatime"
    ];
  };

  # Code lives on Storage2 but keeps its ~/Projects path. A bind mount (rather
  # than a symlink) means realpath stays /home/<user>/Projects, so direnv allow
  # hashes, nix gcroots and jj workspace paths are unaffected.
  fileSystems."/home/${userConfig.username}/Projects" = {
    device = "/home/${userConfig.username}/Storage2/Projects";
    fsType = "none";
    options = [
      "bind"
      "nofail"
      "x-systemd.automount"
      "x-systemd.requires-mounts-for=/home/${userConfig.username}/Storage2"
    ];
  };

  # Periodic TRIM for NVMe longevity (lower overhead than continuous discard)
  services.fstrim.enable = true;

  # Distribute hardware interrupts across cores
  services.irqbalance.enable = true;

  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
    download-buffer-size = 524288000;
  };

  environment.sessionVariables = {
    XDG_PICTURES_DIR = "${userConfig.homeDirectory}/Pictures";
    HYPRSHOT_DIR = "${userConfig.homeDirectory}/Pictures/screenshots";
    NIXOS_OZONE_WL = "1";

    # Proton performance
    PROTON_USE_NTSYNC = "1"; # NTSync for faster Windows synchronization primitives
    PROTON_ENABLE_WAYLAND = "1"; # Native Wayland in Wine (per-game opt-out: PROTON_ENABLE_WAYLAND=0 %command%)

    # NVIDIA shader cache - increase from 1GB default to 10GB
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      vim = "nvim";
    };
  };

}
