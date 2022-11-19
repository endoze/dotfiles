alias mux='tmuxinator'
alias tls='tmux ls'
alias tns='tmux_new'
alias attach='tmux attach-session -t'
alias switch='tmux switch-client -t'
alias tmk='tmux kill-session -t'

compdef attach_completion attach
compdef attach_completion switch
compdef attach_completion tmk
compdef mux_completion mux
