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
}
