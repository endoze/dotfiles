alias attack='siege -t20s -b -c5'
alias c='clear'
alias dnsflush="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder;"
alias edotfiles="$EDITOR ~/.dotfiles"
alias fastlane='bundled_gem_command fastlane'
alias fixterm="infocmp $TERM | sed -E 's/kbs=^[hH]/kbs=\\\177/' > $TERM.ti; tic $TERM.ti; rm $TERM.ti"
alias fs='foreman start'
alias gpu='git fetch origin -v; git fetch upstream -v; git merge upstream/master'
alias gunapply='git stash show -p | git apply -R'
alias gupp='git fetch -p && gup'
alias mina='bundled_gem_command mina'
alias mod="git status --porcelain | sed -ne 's/^ M //p'"
alias nobundle="_run_without_bundle $@"
alias pod='bundled_gem_command pod'
alias pubkey='pbcopy < ~/.ssh/id_rsa.pub'
alias r="echo 'Reloading ~/.zshrc'; source ~/.zshrc"
alias rspec='rspec_command'
alias scan='bundled_gem_command scan'
alias server='ruby -run -e httpd . -p 8080'
alias time='/usr/bin/time'
alias tf='tail -f'
alias whereami='curl http://remote-ip.herokuapp.com'

alias drun='docker run -i -t --rm'
alias dps="docker ps"
alias ds="docker start"
alias de='docker exec'
alias dockerclean='dockercleanc || true && dockercleani || true && dockercleanv'
alias dockercleanc='printf "\n>>> Deleting stopped containers\n\n" && docker ps -aqf status=exited | xargs docker rm'
alias dockercleani='printf "\n>>> Deleting untagged images\n\n" && docker images -qf dangling=true | xargs docker rmi'
alias dockercleanv='printf "\n>>> Deleting dangling volumes\n\n" && docker volume ls -qf dangling=true | xargs docker volume rm'
alias dockerkillall='docker ps -q | xargs docker kill'
alias dc='docker-compose'
alias dcr='docker-compose run --rm'
alias dcu='docker-compose up'
alias dm='docker-machine'
