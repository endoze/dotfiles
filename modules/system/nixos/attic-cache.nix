{ config, pkgs, lib, userConfig, ... }:

let
  serverName = "dosvec";
  endpoint = "https://cache.kahdu.org/";
  substituterUrl = "https://cache.kahdu.org/main";
  publicKey = "main:ch1Il2WBscgvKTDg00wIqQCT/wSyqlA7lD0n2m2VkOg=";
  cacheHost = "cache.kahdu.org";
in
{
  nix.settings = {
    substituters = [ substituterUrl ];
    trusted-public-keys = [ publicKey ];
    netrc-file = config.sops.templates."nix-netrc".path;
  };

  environment.systemPackages = [ pkgs.attic-client ];

  sops.templates."nix-netrc" = {
    content = ''
      machine ${cacheHost}
      login attic
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

  systemd.services.attic-watch-store = {
    description = "Attic - watch /nix/store and push new paths to ${serverName}:main";
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "network-online.target" "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [
      config.sops.secrets."attic-admin-key".sopsFile
      config.sops.templates."attic-config.toml".content
    ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.attic-client}/bin/attic watch-store --jobs 2 ${serverName}:main";
      Restart = "on-failure";
      RestartSec = "10s";
      User = userConfig.username;
      Group = "users";
      NoNewPrivileges = true;
    };
  };
}
