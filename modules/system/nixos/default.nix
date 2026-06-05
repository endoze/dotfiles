{ config, pkgs, lib, userConfig, ... }:

{
  imports = [
    ./dnsmasq.nix
    ../common/github-keys.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix configuration
  nix = {
    package = pkgs.nixVersions.stable;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" ] ++ (if userConfig ? username then [ userConfig.username ] else [ ]);
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Clean /tmp on boot
    tmp.cleanOnBoot = true;

    # Enable NTFS support
    supportedFilesystems = [ "ntfs" ];
  };

  # Networking
  networking = {
    networkmanager.enable = true;
  };

  # Time zone and locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable basic services
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
          "hmac-sha2-512"
        ];
      };
    };

    sshguard = {
      enable = true;
      attack_threshold = 30;
      blocktime = 600;
      detection_time = 1800;
      whitelist = [
        "127.0.0.0/8"
        "100.64.0.0/10"
        "192.168.1.0/24"
      ];
    };

    # Enable CUPS for printing
    printing.enable = true;

    # Enable sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # User configuration
  users.users.${userConfig.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.fish;
    description = userConfig.fullName or "User";
  };

  programs.fish.enable = true;

  # NixOS state version for all hosts (single source of truth). Determines
  # defaults for stateful data (file locations, DB versions, daemon defaults).
  # Bumped 24.05 -> 26.05 deliberately after auditing every gated change in
  # the pinned nixpkgs; the only one that applied to this config was docker's
  # live-restore default, which is pinned explicitly in docker.nix.
  system.stateVersion = "26.05";
}
