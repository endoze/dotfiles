{ config, pkgs, lib, userConfig, ... }:

{
  # Skip mise's checkPhase to avoid lengthy local rebuilds (e.g. aws-lc-sys)
  # when cache.nixos.org doesn't yet have a substitute for the pinned version.
  nixpkgs.overlays = [
    (final: prev: {
      mise = prev.mise.overrideAttrs (_: { doCheck = false; });
    })
  ];

  home.packages = with pkgs; [
    mise
  ];

  # Configure mise environment variables
  home.sessionVariables = {
    # Keep mise data outside of nix store for mutability
    MISE_DATA_DIR = "${config.home.homeDirectory}/.local/share/mise";
  };

  # Link mise configuration with out-of-store symlink for live updates
  xdg.configFile."mise".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/mise";

  # Ensure mise data directory exists with proper permissions
  home.activation.createMiseDataDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.local/share/mise
  '';
}
