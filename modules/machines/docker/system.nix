{ pkgs, lib, userConfig, ... }:

# This module provides a user setup script for Docker containers.
# Since we can't run full NixOS activation in a Docker build,
# we generate a script that creates the user from the NixOS-style config.

let
  username = userConfig.username;
  homeDirectory = userConfig.homeDirectory;
  uid = "1000";
  gid = "100";  # users group
  shell = "${pkgs.fish}/bin/fish";
in
{
  # Script to create the user (mirrors NixOS users.users behavior)
  userSetupScript = pkgs.writeShellScriptBin "setup-user" ''
    set -e

    # Create user group if needed
    if ! getent group ${username} >/dev/null 2>&1; then
      echo "${username}:x:${uid}:" >> /etc/group
    fi

    # Create user if needed
    if ! getent passwd ${username} >/dev/null 2>&1; then
      echo "${username}:x:${uid}:${gid}:${username}:${homeDirectory}:${shell}" >> /etc/passwd
      echo "${username}:!:1::::::" >> /etc/shadow 2>/dev/null || true
    fi

    # Create home directory
    mkdir -p ${homeDirectory}
    chown ${uid}:${gid} ${homeDirectory}

    # Create nix profile directory for user
    mkdir -p /nix/var/nix/profiles/per-user/${username}
    chown ${uid}:${gid} /nix/var/nix/profiles/per-user/${username}
  '';

  # Export for reference
  inherit username homeDirectory uid gid shell;
}
