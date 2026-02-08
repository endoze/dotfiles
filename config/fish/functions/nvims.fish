function nvims
  set items bare chad lvim test
  set config (printf "%s\n" $items | fzf --prompt=" Neovim Config  " --height=50% --layout=reverse --border --exit-0)

  if [ -z $config ]
      echo "Nothing selected"
      return 0
  else if [ $config = "default" ]
      set config ""
  end

  echo $config

  eval "nvim-$config" $argv
end

function nvim-chad
  env NVIM_APPNAME='' nvim $argv
end

function nvim-bare
  env NVIM_APPNAME=bare nvim $argv
end

function nvim-test
  env NVIM_APPNAME=test nvim $argv
end

function nvim-lvim
  ~/.local/bin/lvim $argv
end
