{ config, pkgs, lib, userConfig, ... }:

let
  serverName = "dosvec";
  endpoint = "https://cache.kahdu.org/";
  substituterUrl = "https://cache.kahdu.org/main";
  publicKey = "main:ch1Il2WBscgvKTDg00wIqQCT/wSyqlA7lD0n2m2VkOg=";
  cacheHost = "cache.kahdu.org";
  netrcPath = "/etc/nix/netrc";
in
{
  environment.systemPackages = [ pkgs.attic-client ];

  sops.templates."nix-netrc" = {
    # Root-readable copy used by the Nix daemon (Determinate merges this in
    # via /etc/determinate/config.json -> additionalNetrcSources).
    path = netrcPath;
    content = ''
      machine ${cacheHost}
      login attic
      password ${config.sops.placeholder."attic-admin-key"}
    '';
  };

  sops.templates."user-nix-netrc" = {
    # User-readable copy referenced from home-manager's ~/.config/nix/nix.conf
    # so user-context commands (nix copy --from, nix store info --store, etc.)
    # can authenticate. Same secret as the root copy above; separate file
    # because the sops-rendered root copy is 0400 root and unreadable to user.
    path = "${userConfig.homeDirectory}/.config/nix/netrc";
    owner = userConfig.username;
    mode = "0400";
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

  # PULL side: nix-darwin's nix is disabled in favor of Determinate Nix, so
  # `nix.settings` would be a no-op. Instead we configure the daemon two ways:
  #
  # 1. Determinate's own config tells it to merge our sops-rendered netrc
  #    into the synthesized /nix/var/determinate/netrc — additive, leaves
  #    Determinate's FlakeHub entries intact.
  # 2. An activation script appends substituter + public-key lines to the
  #    machine-local /etc/nix/nix.custom.conf only if absent — preserves
  #    whatever else that file holds (it differs per host).
  environment.etc."determinate/config.json".text = builtins.toJSON {
    authentication.additionalNetrcSources = [ netrcPath ];
  };

  system.activationScripts.postActivation.text = ''
    customConf=/etc/nix/nix.custom.conf
    changed=0
    ensure_line() {
      local line="$1"
      if ! /usr/bin/grep -qxF "$line" "$customConf" 2>/dev/null; then
        printf '%s\n' "$line" >> "$customConf"
        changed=1
      fi
    }
    ensure_line "extra-substituters = ${substituterUrl}"
    ensure_line "extra-trusted-public-keys = ${publicKey}"
    if [ "$changed" -eq 1 ]; then
      /bin/launchctl kickstart -k system/systems.determinate.nix-daemon || true
    fi
  '';

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
