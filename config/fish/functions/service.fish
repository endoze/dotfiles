function service
  if test (count $argv) -lt 1 -o (count $argv) -gt 2
    echo "Usage: service start|stop|list|status <program-name>"

    return 1
  end

  set action $argv[1]
  set program $argv[2]

  if test $action != start -a $action != stop -a $action != status -a $action != list
    echo "Error: First argument must be 'start|stop|status|list."

    return 1
  end

  if is_macos
    switch $action
      case start stop
        launchctl $action org.nix-community.home.$program
      case list
        launchctl list | awk 'NR==1 || /org.nix-community.home/'
      case status
        launchctl list org.nix-community.home.$program
    end
  else if is_linux
    switch $action
      case start
        systemctl --user start $program
      case stop
        systemctl --user stop $program
      case list
        systemctl --user list-units --type=service
      case status
        systemctl --user status $program
    end
  end
end
