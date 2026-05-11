{ config, pkgs, lib, userConfig, ... }:

let
  serverName = "dosvec";
  endpoint = "https://cache.kahdu.org/";
  publicKey = "main:ch1Il2WBscgvKTDg00wIqQCT/wSyqlA7lD0n2m2VkOg=";
  cacheHost = "cache.kahdu.org";
in
{
  environment.systemPackages = [ pkgs.attic-client ];

  sops.templates."nix-netrc" = {
    # Explicit path so the home-manager nix.conf can reference it.
    # nix-daemon runs as root and can read this regardless of mode/owner.
    path = "/etc/nix/netrc";
    content = ''
      machine ${cacheHost}
      password ${config.sops.placeholder."attic-admin-key"}
    '';
  };

  sops.templates."attic-config.toml" = {
    path = "${userConfig.homeDirectory}/.config/attic/config.toml";
    owner = userConfig.username;
    mode = "0400";
    content = ''
      default-server = "${serverName}"

      [servers.${serverName}]
      endpoint = "${endpoint}"
      token = "${config.sops.placeholder."attic-admin-key"}"
    '';
  };

  # Note on substituters (PULL): nix-darwin's nix is disabled in favor of
  # Determinate Nix, so `nix.settings` here would be a no-op. To make this
  # host pull from cache.kahdu.org, configure Determinate's nix.conf
  # separately (e.g. /etc/nix/nix.custom.conf). This module only wires up
  # the PUSH side (watch-store).

  launchd.daemons.attic-watch-store = {
    serviceConfig = {
      Label = "org.kahdu.attic-watch-store";
      ProgramArguments = [
        "${pkgs.attic-client}/bin/attic"
        "watch-store"
        "--jobs"
        "2"
        "${serverName}:main"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      UserName = userConfig.username;
    };
  };
}
