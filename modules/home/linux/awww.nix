{ pkgs, ... }:

let
  awwwRestore = pkgs.writeShellScript "awww-restore" ''
    wallpaper="$HOME/.config/hypr/current-wallpaper"
    until ${pkgs.awww}/bin/awww query >/dev/null 2>&1; do
      sleep 0.1
    done
    if [ -e "$wallpaper" ]; then
      ${pkgs.awww}/bin/awww img "$wallpaper" --transition-type random
    fi
  '';
in
{
  home.packages = [ pkgs.awww ];

  systemd.user.services.awww = {
    Unit = {
      Description = "awww animated wallpaper daemon";
      Documentation = "https://codeberg.org/LGFae/awww";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      ExecStartPost = "${awwwRestore}";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
