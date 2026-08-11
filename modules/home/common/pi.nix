{ config, pkgs, lib, userConfig, inputs, ... }:

let
  # The published @rahularya01/pi-cursor never handles Cursor's `turnEnded`
  # interactionUpdate: it lands in the wire-drift counter instead. Nothing then
  # records that the turn finished, so the GOAWAY Cursor sends right after a
  # completed turn is classified as transport loss, the checkpoint recovery path
  # resumes, and the turn re-runs its tools and re-answers up to three times.
  # Upstream issue #3, fixed by PR #4, which is open and conflicting so it will
  # not land on its own.
  #
  # The patch is that PR rebased onto the pinned v1.4.8 rev. Only native-core.ts
  # conflicted (4 of 11 hunks): the `canCompleteAfterGoaway` import/export
  # plumbing plus one dedup, resolved by hand. `finalizeSuccessfulTurn` also
  # gained the `convKey` argument v1.4.8 added to commitStoredCheckpoint, which
  # the PR predates -- without it the dedup would regress that fix.
  #
  # It also backfills `integrity` for three nested @earendil-works dev
  # dependencies whose lockfile entries omit it, which prefetch-npm-deps rejects
  # ("non-git dependencies should have associated integrity").
  #
  # Built here rather than vendored so no dist/ lands in this repo; only the
  # patch is tracked. Drop all of this once a release carries PR #4.
  #
  # Re-pin: bump the input rev, refresh the patch against it, then set
  # npmDepsHash to lib.fakeHash and take the value nix reports.
  pi-cursor = pkgs.buildNpmPackage {
    pname = "pi-cursor";
    version = "1.4.8";
    src = inputs.pi-cursor;

    patches = [ ../../../config/pi/patches/pi-cursor-pr4-goaway-after-turn-ended.patch ];

    # v1 leaves the nested peer deps out of the cache, so npm ci fails ENOTCACHED.
    npmDepsFetcherVersion = 2;
    npmDepsHash = "sha256-lWdYALAjBrzbT++1AN+4/B12VyshYDkd6PVj6DlPAGs=";
  };

  # The directory pi points at: holds package.json (whose `pi.extensions` names
  # dist/index.js), dist/, and the runtime node_modules.
  pi-cursor-package = "${pi-cursor}/lib/node_modules/@rahularya01/pi-cursor";
in
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

    # In-store on purpose: this is a build output, not something to hand-edit.
    # settings.json refers to it as "./local/pi-cursor"; relative package paths
    # in user settings resolve against ~/.pi/agent (PackageManager's agentDir),
    # not against the settings file, so the entry stays machine-independent.
    ".pi/agent/local/pi-cursor".source = pi-cursor-package;
  };
}
