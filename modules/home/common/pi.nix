{ config, pkgs, lib, userConfig, ... }:

{
  programs.pi-coding-agent = {
    enable = true;

    # pi shells out to npm to install the packages declared in settings.json.
    # These are appended with --suffix, so a mise-managed npm earlier in PATH
    # still wins; this is the fallback that makes pi self-sufficient on Darwin,
    # where cli.nix only installs nodejs on Linux.
    extraPackages = [ pkgs.nodejs ];
  };

  # settings.json carries `lastChangelogVersion = "999.0.0"` as a sentinel. pi
  # shows every changelog entry newer than that value on interactive startup and
  # only rewrites the key when it finds some, so a version nothing can exceed
  # suppresses the "What's New" banner permanently. JSON takes no comments, hence
  # the note here. Drop it to the real version to start seeing changelogs again,
  # or set `collapseChangelog = true` there for a one-line summary instead.
  #
  # The `packages` list in that file is pi's own package manager, not Nix.
  # pi-cursor is `npm:@rahularya01/pi-cursor@<version>`: upstream publishes the
  # built dist/ to npm, and a versioned spec is pinned and skipped by
  # `pi update --extensions`, so the pin lives in this repo and only moves when
  # the spec is edited. Bump it with `pi install npm:@rahularya01/pi-cursor@<v>`.
  #
  # Deliberately not programs.pi-coding-agent.settings: that option renders the
  # file into the Nix store read-only, but pi rewrites settings.json at runtime
  # (/model, /theme, pi install, lastChangelogVersion) via a plain writeFileSync
  # through this path. An out-of-store symlink keeps the file writable and lands
  # pi's own edits directly in this repo.
  home.file = lib.mkIf config.programs.pi-coding-agent.enable {
    ".pi/agent/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/pi/settings.json";

    # pi auto-discovers ~/.pi/agent/extensions/*.ts (and */index.ts) with no
    # settings.json entry, and loads them through jiti, so TypeScript needs no
    # build step. Symlinking the directory keeps the sources in this repo and
    # makes edits live: /reload in pi, no rebuild.
    ".pi/agent/extensions".source =
      config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/pi/extensions";

    # pi discovers ~/.pi/agent/themes/*.json with no settings.json entry beyond
    # the `theme` name itself. Out-of-store again so palette tweaks land on the
    # next /theme (or restart) without a rebuild.
    ".pi/agent/themes".source =
      config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/pi/themes";

    # ~/.pi/agent/skills/ is a global skill location pi scans at startup with no
    # settings.json entry: every subdirectory holding a SKILL.md registers as a
    # /skill:<name> command. Out-of-store so editing a SKILL.md takes effect on
    # the next pi start rather than a rebuild.
    ".pi/agent/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/pi/skills";
  };
}
