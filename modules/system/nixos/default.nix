{ config, pkgs, lib, userConfig, ... }:

{
  imports = [
    ./dnsmasq.nix
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
      };
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

  system.stateVersion = "24.05";
}
