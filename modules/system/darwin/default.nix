{ config, pkgs, lib, userConfig ? { }, ... }:

let
  username = userConfig.username or "work-user";
in
{
  imports = [
    ./dnsmasq.nix
  ];

  # Disable nix-darwin's management of Nix since we're using Determinate Nix
  # Determinate Nix handles the nix daemon and configuration itself
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    coreutils
    curl
    fish
    vim
  ];

  # Enable Touch ID for sudo  
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    controlcenter.BatteryShowPercentage = true;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain.InitialKeyRepeat = 15;
    dock.autohide = true;
    dock.orientation = "left";
    dock.magnification = false;
    dock.show-recents = false;
    dock.tilesize = 32;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder.FXPreferredViewStyle = "icnv";
    screencapture.location = "~/Pictures/screenshots";
    LaunchServices.LSQuarantine = false;
  };

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Platform specific
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 6;

  # IMPORTANT: This requires the actual macOS username to be set in users.local.nix
  # The username must match an existing user on the system
  system.primaryUser = username;

  # User configuration - define the user for nix-darwin
  users.users.${username} = {
    name = username;
    home = userConfig.homeDirectory or "/Users/${username}";
  };
}
