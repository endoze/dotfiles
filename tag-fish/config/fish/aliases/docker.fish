alias dc 'docker compose'
alias dcr 'docker compose run --rm'
alias dcu 'docker compose up'
alias de 'docker exec'
alias dockerclean 'dockercleanc || true && dockercleani || true && dockercleanv'
alias dockercleanc 'printf "\n>>> Deleting stopped containers\n\n" && docker ps -aqf status=exited | xargs docker rm'
alias dockercleani 'printf "\n>>> Deleting untagged images\n\n" && docker images -qf dangling=true | xargs docker rmi'
alias dockercleanv 'printf "\n>>> Deleting dangling volumes\n\n" && docker volume ls -qf dangling=true | xargs docker volume rm'
alias dockerkillall 'docker ps -q | xargs docker kill'
alias dps "docker ps"
alias drun 'docker run -i -t --rm'
alias ds "docker start"
