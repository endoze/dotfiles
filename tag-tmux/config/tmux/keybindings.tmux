# vim: filetype=tmux
#
# Set the prefix to Ctrl+a
set-option -g   prefix C-a
unbind C-b
bind-key C-a    send-prefix
set -g prefix C-a

# Disable mouse use
set -g mouse off

# Remap keys to my settings
unbind-key d        ; bind-key d        detach-client
unbind-key Tab      ; bind-key Tab      choose-window
unbind-key t        ; bind-key t        new-window
unbind-key `        ; bind-key `        last-window
unbind-key n        ; bind-key n        next-window
unbind-key p        ; bind-key p        previous-window

# Window selection
unbind-key 1        ; bind-key 1        select-window -t 1
unbind-key 2        ; bind-key 2        select-window -t 2
unbind-key 3        ; bind-key 3        select-window -t 3
unbind-key 4        ; bind-key 4        select-window -t 4
unbind-key 5        ; bind-key 5        select-window -t 5
unbind-key 6        ; bind-key 6        select-window -t 6
unbind-key 7        ; bind-key 7        select-window -t 7
unbind-key 8        ; bind-key 8        select-window -t 8
unbind-key 9        ; bind-key 9        select-window -t 9
unbind-key 0        ; bind-key 0        select-window -t 10
unbind-key M-1      ; bind-key -n M-1   select-window -t 1
unbind-key M-2      ; bind-key -n M-2   select-window -t 2
unbind-key M-3      ; bind-key -n M-3   select-window -t 3
unbind-key M-4      ; bind-key -n M-4   select-window -t 4
unbind-key M-5      ; bind-key -n M-5   select-window -t 5
unbind-key M-6      ; bind-key -n M-6   select-window -t 6
unbind-key M-7      ; bind-key -n M-7   select-window -t 7
unbind-key M-8      ; bind-key -n M-8   select-window -t 8
unbind-key M-9      ; bind-key -n M-9   select-window -t 9
unbind-key M-0      ; bind-key -n M-0   select-window -t 10

# Copy mode
set-window-option -g mode-keys vi
set-option buffer-limit 10
unbind Escape           ; bind Escape      copy-mode
unbind P                ; bind P           paste-buffer
unbind-key -T copy-mode-vi v ; bind -T copy-mode-vi v send-keys -X begin-selection
unbind-key -T copy-mode-vi y ; bind -T copy-mode-vi y send-keys -X copy-selection
unbind-key -T copy-mode-vi b ; bind-key -T copy-mode-vi b send-keys -X rectangle-toggle

# Zoom tmux pane with '+' key
bind + resize-pane -Z
