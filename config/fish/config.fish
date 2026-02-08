export LSCOLORS=ExFxCxDxBxegedabagacad
export CLICOLOR="YES"
export DOTFILES=$HOME/.dotfiles
export EDITOR="nvim"
export STARSHIP_LOG=error
export XDG_CONFIG_HOME=$HOME/.config
export RUBY_YJIT_ENABLE=1

for f in $HOME/.config/fish/aliases/*fish
  source $f
end

if test -e ~/.localrc.fish
  source ~/.localrc.fish
end

if status is-interactive && command -v starship >/dev/null 2>&1
  # stop visual bell from doing anything
  printf "\e[?1042l"

  starship init fish | source
  direnv hook fish | source
end
