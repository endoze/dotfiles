which rbenv > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo $PATH | grep -q ".rbenv/shims"

  if [[ $? -eq 1 ]]; then
    eval "$(rbenv init -)"
  fi
fi
