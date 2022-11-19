# statusbar
set-option -g   status-interval 0
set-option -g   status-justify left
set-option -g   status-left-length 20
set-option -g   status-left ' #h |'
set-option -g   status-right ' | %m-%d-%Y %I:%M%p #[default]'

#### COLOUR (Solarized dark theme)
# https://github.com/seebi/tmux-colors-solarized/blob/master/tmuxcolors-dark.conf

# default statusbar colors
# set-option -g status-style fg=yellow,bg=black #yellow and base02

# default window title colors
# set-window-option -g window-status-style fg=brightblue,bg=default #base0 and default
#set-window-option -g window-status-style dim

# active window title colors
# set-window-option -g window-status-current-style fg=brightred,bg=default #orange and default
#set-window-option -g window-status-current-style bright

# pane border
# set-option -g pane-border-style fg=black #base02
# set-option -g pane-active-border-style fg=brightgreen #base01

# message text
# set-option -g message-style fg=brightred,bg=black #orange and base01

# pane number display
# set-option -g display-panes-active-colour blue #blue
# set-option -g display-panes-colour brightred #orange

# clock
# set-window-option -g clock-mode-colour green #green

# bell
# set-window-option -g window-status-bell-style fg=black,bg=red #base02, red

#### COLOUR (Solarized light)
# https://github.com/seebi/tmux-colors-solarized/blob/master/tmuxcolors-light.conf

# default statusbar colors
set-option -g status-style fg=yellow,bg=white #yellow and base2

# default window title colors
set-window-option -g window-status-style fg=brightyellow,bg=default #base0 and default
#set-window-option -g window-status-style dim

# active window title colors
set-window-option -g window-status-current-style fg=brightred,bg=default #orange and default
#set-window-option -g window-status-current-style bright

# pane border
set-option -g pane-border-style fg=white #base2
set-option -g pane-active-border-style fg=brightcyan #base1

# message text
set-option -g message-style fg=brightred,bg=white #orange and base2

# pane number display
set-option -g display-panes-active-colour blue #blue
set-option -g display-panes-colour brightred #orange

# clock
set-window-option -g clock-mode-colour green #green

# bell
set-window-option -g window-status-bell-style fg=white,bg=red #base2, red
