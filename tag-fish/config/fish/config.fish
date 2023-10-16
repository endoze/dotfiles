export LSCOLORS=ExFxCxDxBxegedabagacad
export CLICOLOR="YES"
export DOTFILES=$HOME/.dotfiles
export EDITOR="nvim"
export RCRC=$DOTFILES/rcrc
export STARSHIP_LOG=error

for f in $HOME/.config/fish/aliases/*fish
  source $f
end

if test -e ~/.localrc.fish
  source ~/.localrc.fish
end

if status is-interactive
  starship init fish | source
end
