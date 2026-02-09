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
    # Basic pipewire without device-specific config
    ../../system/nixos/pipewire-basic.nix
  ];

  networking.hostName = systemConfig.hostName or "tiesto";

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
    extraGroups = [ "pipewire" ];
    openssh.authorizedKeys.keys = publicKeys;
  };

  # EFI boot partition is at /boot/efi on this machine
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Use CachyOS kernel with BORE scheduler (includes T2 patches)
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # T2 MacBook kernel parameters
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "pcie_ports=compat"
    # WiFi fix for wpa_supplicant 2.11 regression
    "brcmfmac.feature_disable=0x82000"
  ];

  # Enable redistributable firmware (needed for T2 WiFi/Bluetooth)
  hardware.enableRedistributableFirmware = true;

  # T2 MacBook WiFi/Bluetooth firmware (stored at /etc/nixos/firmware/brcm on the machine)
  hardware.firmware = [
    (pkgs.stdenvNoCC.mkDerivation {
      name = "brcm-firmware";
      src = /etc/nixos/firmware/brcm;
      installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        cp $src/* "$out/lib/firmware/brcm"
      '';
    })
  ];

  # Intel graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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
