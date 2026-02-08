function drmgrep
  set container_pattern $argv[1]
  docker ps -a | grep $container_pattern | awk '{ print $1 }' | xargs docker rm
end
