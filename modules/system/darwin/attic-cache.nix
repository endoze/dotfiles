{ config, pkgs, lib, userConfig, ... }:

let
  serverName = "dosvec";
  endpoint = "https://cache.kahdu.org/";
  substituterUrl = "https://cache.kahdu.org/main";
  publicKey = "main:ch1Il2WBscgvKTDg00wIqQCT/wSyqlA7lD0n2m2VkOg=";
  cacheHost = "cache.kahdu.org";
  netrcPath = "/etc/nix/netrc";
  rootAtticConfigPath = "/var/root/.config/attic/config.toml";
  fifoPath = "/var/run/attic-push.fifo";

  # post-build-hook runs as root from the Nix daemon for each successful
  # derivation. To avoid spawning a fresh `attic push` per build (which
  # caused a concurrency storm of 404/502s against the Attic server), the
  # hook just appends each $OUT_PATH on its own line to a FIFO. A single
  # persistent launchd daemon (attic-push-stdin) reads the FIFO and pushes
  # paths serially via `attic push --stdin`. The `|| true` swallows write
  # failures so a temporarily-dead daemon never fails a build; KeepAlive on
  # the launchd job will restart it.
  postBuildHook = pkgs.writeShellScript "attic-post-build-hook" ''
    set -eu
    [ -z "''${OUT_PATHS:-}" ] && exit 0
    for p in $OUT_PATHS; do
      printf '%s\n' "$p"
    done >> ${fifoPath} 2>/dev/null || true
    exit 0
  '';
  postBuildHookPath = "/etc/attic/post-build-hook.sh";
in
{
  environment.systemPackages = [ pkgs.attic-client ];

  # Stable /etc symlink so the nix.custom.conf line never needs to change
  # even when the hook script's store hash does.
  environment.etc."attic/post-build-hook.sh".source = postBuildHook;

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

  sops.templates."attic-config-root.toml" = {
    # Root copy so the daemon-spawned post-build-hook can authenticate to
    # the cache. /var/root is the macOS root home; HOME=/var/root in the
    # hook script makes attic find this config.
    path = rootAtticConfigPath;
    owner = "root";
    mode = "0400";
    content = ''
      default-server = "${serverName}"

      [servers.${serverName}]
      endpoint = "${endpoint}"
      token = "${config.sops.placeholder."attic-admin-key"}"
    '';
  };

  # PULL side: nix-darwin's nix is disabled in favor of Determinate Nix, so
  # `nix.settings` would be a no-op. Instead we configure the daemon three
  # ways via files Determinate respects:
  #
  # 1. /etc/determinate/config.json tells determinate-nixd to merge our
  #    sops-rendered netrc into the synthesized /nix/var/determinate/netrc -
  #    additive, leaves Determinate's FlakeHub entries intact.
  # 2. Activation script appends substituter + public-key lines to
  #    /etc/nix/nix.custom.conf only if absent - preserves whatever else
  #    that file holds (it differs per host).
  # 3. Same activation script also ensures `post-build-hook = ...` is in
  #    nix.custom.conf so every successful build triggers the cache push.
  #    macOS FSEvents doesn't reliably report /nix/store changes (separate
  #    APFS volume), so `attic watch-store` doesn't catch new paths the way
  #    it does on Linux - the post-build-hook is the supported alternative.
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
    ensure_line "post-build-hook = ${postBuildHookPath}"
    if [ "$changed" -eq 1 ]; then
      /bin/launchctl kickstart -k system/systems.determinate.nix-daemon || true
    fi

    # Ensure the FIFO that feeds the attic-push-stdin daemon exists with the
    # right permissions. /var/run is the conventional macOS location for
    # runtime pipes; it doesn't survive reboots, so we recreate every
    # activation. We recreate unconditionally so that a stale inode from a
    # previous boot or rebuild is replaced, then kickstart the daemon so it
    # reopens the new inode.
    /bin/rm -f ${fifoPath}
    /usr/bin/mkfifo -m 0600 ${fifoPath}
    /usr/sbin/chown root:wheel ${fifoPath}
    /bin/launchctl kickstart -k system/org.kahdu.attic-push-stdin || true
  '';

  # Persistent daemon that consumes paths from the FIFO and pushes them to
  # the Attic cache serially via `attic push --stdin`. Replaces the previous
  # approach of backgrounding one `attic push` per derivation, which caused
  # concurrency-induced 404/502s against the server.
  #
  # The `exec 3<>${fifoPath}` open keeps a writer FD around inside the
  # daemon itself, so `attic push --stdin` never sees EOF when the hook
  # writer briefly closes between bursts - without this, the daemon would
  # exit after every quiet period and KeepAlive would flap. HOME=/var/root
  # makes attic find /var/root/.config/attic/config.toml for credentials.
  #
  # Output is captured to /var/log/attic-push.log, the conventional macOS
  # location for daemon logs. newsyslog (Apple's built-in rotator, run hourly
  # by /System/Library/LaunchDaemons/com.apple.newsyslog.plist) trims and
  # gzips it per the rule installed below. Tail with:
  #   tail -f /var/log/attic-push.log
  launchd.daemons.attic-push-stdin = {
    serviceConfig = {
      Label = "org.kahdu.attic-push-stdin";
      ProgramArguments = [
        "/bin/sh" "-c"
        "exec 3<>${fifoPath}; exec ${pkgs.attic-client}/bin/attic push ${serverName}:main --stdin <&3"
      ];
      EnvironmentVariables = {
        HOME = "/var/root";
      };
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/attic-push.log";
      StandardErrorPath = "/var/log/attic-push.log";
    };
  };

  # newsyslog rule: rotate at 1 MB, keep 5 gzip-compressed archives.
  # Format: logfilename [owner:group] mode count size when flags
  #   size  = KB threshold (1024 = 1 MB)
  #   when  = '*' means size-triggered only (no time-based rotation)
  #   flags = Z (gzip rotated logs), N (don't signal any process post-rotate;
  #           launchd reopens the file on next write because we don't hold
  #           it open across rotations - simple StandardOutPath redirect)
  environment.etc."newsyslog.d/attic-push.conf".text = ''
    /var/log/attic-push.log    root:wheel    644  5    1024  *     ZN
  '';
}
