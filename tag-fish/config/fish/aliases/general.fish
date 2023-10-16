alias attach "tmux attach -t"
alias attack 'siege -t20s -b -c5'
alias c 'clear'
alias cat bat
alias dnsflush "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder;"
alias edotfiles "$EDITOR ~/.dotfiles"
alias fastlane 'bundled_gem_command fastlane'
alias fixterm "infocmp $TERM | sed -E 's/kbs=^[hH]/kbs=\\\177/' > $TERM.ti; tic $TERM.ti; rm $TERM.ti"
alias fs 'foreman start'
alias k 'kubectl'
alias ls lsd
alias mina 'bundled_gem_command mina'
alias mkctl 'microk8s kubectl'
alias mod "git status --porcelain | sed -ne 's/^ M //p'"
alias mux tmuxinator
alias nobundle "_run_without_bundle $argv"
alias pod 'bundled_gem_command pod'
alias proj 'cd ~/Projects'
alias pubkey 'pbcopy < ~/.ssh/id_rsa.pub'
alias r "echo 'Reloading ~/.config/fish/config.fish'; source ~/.config/fish/config.fish"
alias rspec 'rspec_command'
alias scan 'bundled_gem_command scan'
alias server 'ruby -run -e httpd . -p 8080'
alias tf 'tail -f'
alias vim nvim
alias whereami 'curl http://remote-ip.herokuapp.com'
