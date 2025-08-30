function __fish_tmux_windows
  tmux list-windows -F "#{window_index}:#{window_name}"
end

# Use the function for autocompletion
complete -c txcp -a '(__fish_tmux_windows)'
