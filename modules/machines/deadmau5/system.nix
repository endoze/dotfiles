{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

let
  githubUser = userConfig.username;
  publicKeysFile = builtins.readFile (pkgs.fetchurl {
    url = "https://github.com/${githubUser}.keys";
    sha256 = "6KWN+v3skxU1/h0aJBtE/Opli22VFIsv+Z/f3P7oCgs=";
  });
  publicKeys = lib.splitString "\n" (lib.removeSuffix "\n" publicKeysFile);
in
{
  imports = [
    ./hardware-configuration.nix
    ../../system/meta/cli-nixos.nix
    ../../system/meta/gui-nixos.nix
    # Machine-specific: nvidia GPU and custom pipewire config
    ../../system/nixos/nvidia.nix
    ../../system/nixos/pipewire.nix
  ];

  # Use nvidia driver for Xorg/Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  services.dnsmasq-resolver.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Allow input group to create virtual input devices (for Sunshine gamepad/keyboard/mouse)
  # Set NVMe I/O scheduler to none (NVMe has internal scheduling, software scheduler adds CPU overhead)
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # Ensure Sunshine starts after graphical session is ready
  systemd.user.services.sunshine = {
    after = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    serviceConfig.Restart = "on-failure";
  };

  # Tailscale as exit node and route advertiser for remote LAN access
  services.tailscale = {
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--exit-node="
      "--accept-routes=false"
      "--advertise-exit-node"
      "--advertise-routes=192.168.1.0/24"
    ];
  };

  networking.hostName = systemConfig.hostName or "deadmau5";

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
    extraGroups = [ "pipewire" "input" ];
    openssh.authorizedKeys.keys = publicKeys;
  };

  # Use CachyOS LTS kernel (6.18) with BORE scheduler for better desktop/gaming performance
  # The "latest" (6.19) kernel is incompatible with nvidia open modules
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-lts;

  boot.kernelParams = [
    "mitigations=off"              # ~5-15% perf gain on Intel (disables Spectre/Meltdown mitigations)
    "split_lock_detect=off"        # Prevents severe perf penalty in some Proton games (God of War, etc.)
    "transparent_hugepage=madvise" # THP only for apps that request it (Proton/CUDA do, avoids overhead for others)
    "threadirqs"                   # Move IRQ handlers to schedulable kernel threads
    "nowatchdog"                   # Disable watchdog timers (reduces interrupts)
    "nmi_watchdog=0"               # Disable NMI watchdog
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
    "vm.swappiness" = 150;                   # With zram: prefer compressing into zram over evicting file cache
    "vm.vfs_cache_pressure" = 50;            # Hold filesystem metadata in memory longer
    "vm.dirty_bytes" = 268435456;            # 256 MB dirty limit before synchronous writeback
    "vm.dirty_background_bytes" = 134217728; # 128 MB before background writeback starts
    "vm.dirty_writeback_centisecs" = 1000;   # Flush every 10s instead of 5s
    "vm.dirty_expire_centisecs" = 1000;
    "vm.compaction_proactiveness" = 0;       # Disable proactive compaction (reduces background CPU)
    "vm.watermark_boost_factor" = 1;         # Less aggressive page reclaim
    "vm.min_free_kbytes" = 131072;           # 128 MB free minimum (prevents allocation stalls during CUDA ops)
    "vm.overcommit_memory" = 1;              # Allow overcommit (important for Ollama/Proton)
    "vm.page_lock_unfairness" = 1;           # Reduce lock contention
    "vm.page-cluster" = 0;                   # Disable swap readahead (NVMe is fast enough)

    # Kernel
    "kernel.split_lock_mitigate" = 0;        # Belt and suspenders with boot param
    "kernel.printk" = "3 3 3 3";             # Reduce printk overhead

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
    XDG_RUNTIME_DIR = "/run/user/1000";
    XDG_PICTURES_DIR = "${userConfig.homeDirectory}/Pictures";
    HYPRSHOT_DIR = "${userConfig.homeDirectory}/Pictures/screenshots";
    NIXOS_OZONE_WL = "1";

    # Proton performance
    PROTON_USE_NTSYNC = "1";       # NTSync for faster Windows synchronization primitives
    PROTON_ENABLE_WAYLAND = "1";   # Native Wayland in Wine (per-game opt-out: PROTON_ENABLE_WAYLAND=0 %command%)

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05";
}
