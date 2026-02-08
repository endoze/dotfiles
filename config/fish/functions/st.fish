function __list_themes
  set -l themes onedark palenight solarized_dark solarized_light tokyonight tokyonight_storm

  for theme in $themes
    echo $theme
  end
end

function __ghostty_theme_map
 switch $argv[1]
   case "onedark"
      echo "One-Dark"
   case "palenight"
      echo "PaleNightHC"
   case "solarized_dark"
      echo "iTerm2 Solarized Dark"
   case "solarized_light"
      echo "iTerm2 Solarized Light"
   case "tokyonight"
      echo "tokyonight"
   case "tokyonight_storm"
      echo "tokyonight-storm"
   case '*'
      echo ""
 end
end

function ghostty_switch_theme
  set -l file_path ~/.config/ghostty/config
  set -l target_path (readlink -f $file_path)
  set -l new_theme $argv[1]

  if test -z "$new_theme"
    echo "Usage: ghostty_switch_theme <new-theme-name>"

    return 1
  end

  set -l themes (__list_themes)

  if not contains $new_theme $themes
    echo "Error: Theme '$new_theme' not found. Available themes are:"

    for theme in $themes
      echo "  $theme"
    end

    return 1
  end

  # Get the ghostty theme name from our mapping function
  set -l ghostty_theme (__ghostty_theme_map $new_theme)

  if test -z "$ghostty_theme"
    echo "Error: No mapping found for theme '$new_theme'"

    return 1
  end

  sed -i '' "s|theme = [^[:space:]]*|theme = $ghostty_theme|" $target_path
  echo "Ghostty theme switched to $ghostty_theme"
end

function nvim_switch_theme
  set -l file_path ~/.config/nvim/lua/chadrc.lua
  set -l target_path (readlink -f $file_path)
  set -l new_theme $argv[1]

  if test -z "$new_theme"
    echo "Usage: nvim_switch_theme <new-theme-name>"

    return 1
  end

  set -l themes (__list_themes)

  if not contains $new_theme $themes
    echo "Error: Theme '$new_theme' not found. Available themes are:"

    for theme in $themes
      echo "  $theme"
    end

    return 1
  end

  sed -i '' "s|theme = \"[^\"]*\",|theme = \"$new_theme\",|" $target_path

  echo "Nvim theme switched to $new_theme"
end

function tmux_switch_theme
  set -l file_path ~/.config/tmux/user.plugins
  set -l target_path (readlink -f $file_path)
  set -l new_theme $argv[1]

  if test -z "$new_theme"
    echo "Usage: tmux_switch_theme <new-theme-name>"

    return 1
  end

  set -l themes (__list_themes)

  if not contains $new_theme $themes
    echo "Error: Theme '$new_theme' not found. Available themes are:"

    for theme in $themes
      echo "  $theme"
    end

    return 1
  end

  sed -i '' "s|set -g @theme-name \"[^\"]*\"|set -g @theme-name \"$new_theme\"|" $target_path
  tmux source-file ~/.tmux.conf

  echo "Tmux theme switched to $new_theme"
end


function st
  set -l new_theme $argv[1]

  set -l themes (__list_themes)

  if not contains $new_theme $themes
    echo "Error: Theme '$new_theme' not found. Available themes are:"

    for theme in $themes
      echo "  $theme"
    end

    return 1
  end

  nvim_switch_theme $new_theme
  tmux_switch_theme $new_theme
  ghostty_switch_theme $new_theme
end

complete -c nvim_switch_theme -n 'not __fish_seen_subcommand_from' -f -a '(__list_themes)'
complete -c ghostty_switch_theme -n 'not __fish_seen_subcommand_from' -f -a '(__list_themes)'
complete -c tmux_switch_theme -n 'not __fish_seen_subcommand_from' -f -a '(__list_themes)'
complete -c st -n 'not __fish_seen_subcommand_from' -f -a '(__list_themes)'
