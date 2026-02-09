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
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
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

  # Use CachyOS kernel with BORE scheduler for better desktop/gaming performance
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Enable sched-ext with scx_rusty scheduler for improved gaming performance
  # services.scx = {
  #   enable = true;
  #   scheduler = "scx_rusty";
  # };

  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
      "https://chaotic-nyx.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
    download-buffer-size = 524288000;
  };

  environment.sessionVariables = {
    XDG_RUNTIME_DIR = "/run/user/1000";
    XDG_PICTURES_DIR = "${userConfig.homeDirectory}/Pictures";
    HYPRSHOT_DIR = "${userConfig.homeDirectory}/Pictures/screenshots";
    NIXOS_OZONE_WL = "1";
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
