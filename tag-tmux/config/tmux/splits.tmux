# Window splitting
unbind-key \        ; bind-key \\       split-window -h
unbind-key |        ; bind-key |        split-window -h
unbind-key -        ; bind-key -        split-window -v

# Pane selection and resizing
unbind-key left     ; bind-key left     select-pane -L
unbind-key up       ; bind-key up       select-pane -U
unbind-key down     ; bind-key down     select-pane -D
unbind-key right    ; bind-key right    select-pane -R
unbind-key C-h      ; bind-key C-h      select-pane -L
unbind-key C-k      ; bind-key C-k      select-pane -U
unbind-key C-j      ; bind-key C-j      select-pane -D
unbind-key C-l      ; bind-key C-l      select-pane -R
unbind-key j        ; bind-key -r j     resize-pane -D 5
unbind-key k        ; bind-key -r k     resize-pane -U 5
unbind-key h        ; bind-key -r h     resize-pane -L 5
unbind-key l        ; bind-key -r l     resize-pane -R 5
unbind-key C-left   ; bind-key -r C-left    resize-pane -L 1
unbind-key C-right  ; bind-key -r C-right   resize-pane -R 1
unbind-key C-up     ; bind-key -r C-up  resize-pane -U 1
unbind-key C-down   ; bind-key -r C-down    resize-pane -D 1
unbind-key @        ; bind-key @        confirm-before kill-window
unbind-key r        ; bind-key r        source-file ~/.tmux.conf \; display "Reloaded!"
unbind-key q        ; bind-key q        list-keys
