if [ "$(uname -s)" = "Darwin" ]; then
  which brew > /dev/null 2>&1

  if [[ $? -eq 1 ]]; then
    echo $PATH | grep -q "homebrew"

    if [[ $? -eq 1 ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
fi
