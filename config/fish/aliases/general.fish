alias attach "tmux attach-session -c ~/Projects -t"
alias c 'clear'
alias cat bat
alias edotfiles "pushd ~/.dotfiles; $EDITOR .; popd"
alias fixterm "infocmp $TERM | sed -E 's/kbs=^[hH]/kbs=\\\177/' > $TERM.ti; tic $TERM.ti; rm $TERM.ti"
alias k 'kubectl'
alias kns 'kubens'
alias kcx 'kubectx'
alias ls lsd
alias mod "git status --porcelain | sed -ne 's/^ M //p'"
alias proj 'cd ~/Projects'
alias r "echo 'Reloading ~/.config/fish/config.fish'; source ~/.config/fish/config.fish"
alias server 'ruby -run -e httpd . -p 8080'
alias tf 'tail -f'
alias vim nvim
alias whereami 'curl http://remote-ip.herokuapp.com'
