-- eww is started via systemd (modules/home/linux/eww.nix) so SNI clients can
-- order themselves After=eww.service and avoid racing for the systray watcher.
hl.on("hyprland.start", function()
  -- Retried: xrdb needs XWayland's DISPLAY, which is not necessarily up when
  -- this fires. A single attempt can fail silently and leave XWayland apps
  -- unscaled for the whole session.
  hl.exec_cmd([[for i in $(seq 1 50); do echo 'Xft.dpi: 192' | xrdb -merge 2>/dev/null && break; sleep 0.2; done]])
end)
