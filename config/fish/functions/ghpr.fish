function ghpr
  set output (gh pr create --fill)

  echo $output

  set url (echo $output | grep -o 'https://github.com/[^[:space:]]*' | tr -d '\n')

  if is_macos
    echo $url | pbcopy
  else if is_linux
    if command -v xclip >/dev/null 2>&1
      echo $url | xclip -selection clipboard
    else if command -v xsel >/dev/null 2>&1
      echo $url | xsel --clipboard --input
    end
  end
end
