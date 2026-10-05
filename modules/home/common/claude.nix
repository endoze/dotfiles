{ config, pkgs, lib, sourceRoot, userConfig, ... }:

let
  claudeSource = "${userConfig.dotfilesPath}/config/claude";
  link = path: {
    name = ".claude/${path}";
    value.source = config.lib.file.mkOutOfStoreSymlink "${claudeSource}/${path}";
  };
  dirEntries = dir: map (name: "${dir}/${name}")
    (builtins.attrNames (builtins.readDir (sourceRoot + "/config/claude/${dir}")));

  settingsBase = lib.recursiveUpdate
    (builtins.fromJSON (builtins.readFile (sourceRoot + "/config/claude/settings.base.json")))
    {
      extraKnownMarketplaces.dotfiles-mods.source = {
        source = "directory";
        path = "${claudeSource}/mods";
      };
    };
  settingsBaseFile = pkgs.writeText "claude-settings-base.json" (builtins.toJSON settingsBase);
  jq = lib.getExe pkgs.jq;
in
{
  home.file = builtins.listToAttrs (map link ([
    "CLAUDE.md"
    "keybindings.json"
    "statusline.sh"
    "rules"
    "skills"
    "hooks/code-review-layer.sh"
    # Linked but not registered while superpowers is uninstalled. To use it
    # again, re-add its hooks to settings.base.json (see jj history).
    "hooks/superpowers-jj.sh"
  ]
  ++ dirEntries "hooks/superpowers-jj"));

  # Claude Code rewrites settings.json at runtime (/model, /effort, plugin
  # toggles), so it stays a writable file and the shared base is merged in.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    $DRY_RUN_CMD mkdir -p "$HOME/.claude"
    if [ ! -e "$settings" ]; then
      $DRY_RUN_CMD install -m 600 ${settingsBaseFile} "$settings"
    else
      merged=$(mktemp)
      if ${jq} --slurpfile base ${settingsBaseFile} -f ${sourceRoot}/config/claude/settings-merge.jq "$settings" > "$merged"; then
        if ! ${jq} -e --slurpfile a "$merged" --slurpfile b "$settings" -n '$a == $b' > /dev/null; then
          $DRY_RUN_CMD cp "$settings" "$settings.pre-merge"
          $DRY_RUN_CMD install -m 600 "$merged" "$settings"
        fi
      else
        echo "claude.nix: $settings is not valid JSON, skipping merge" >&2
      fi
      rm -f "$merged"
    fi
  '';
}
