if status is-interactive
  if not command -s mise > /dev/null
    echo "mise: command not found. Install mise to manage language versions"
  end

  set -l mise_shims_dir "$HOME/.local/share/mise/shims"

  if test -d $mise_shims_dir
    fish_add_path -m $mise_shims_dir
  end
end
