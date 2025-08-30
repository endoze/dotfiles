function txcp
    set layout_window $argv[1]
    set layout (tmux list-windows -F "#{window_index} #{window_layout}" | grep '^1' | awk '{print $2}')

    tmux select-layout $layout
end
