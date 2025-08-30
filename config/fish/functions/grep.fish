function grep
  command grep $argv | command grep -v grep
end
