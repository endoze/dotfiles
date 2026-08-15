if not status is-interactive
    exit
end

# Ctrl-G opens the current command line in $EDITOR (nvim), alongside fish's
# built-in alt-e/alt-v bindings for the same thing. This shadows the preset
# ctrl-g "cancel" binding; escape still cancels the pager/search.
for mode in default insert visual
    bind --mode $mode ctrl-g edit_command_buffer
end
