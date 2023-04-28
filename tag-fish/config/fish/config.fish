export LSCOLORS=ExFxCxDxBxegedabagacad
export CLICOLOR="YES"
export DOTFILES=$HOME/.dotfiles
export EDITOR="nvim"
export RCRC=$DOTFILES/rcrc
export VMCTLDIR=$HOME/.docker-vm
export DOCKER_HOST="tcp://192.168.64.2:2375"

for f in $HOME/.config/fish/aliases/*fish
  source $f
end

starship init fish | source
