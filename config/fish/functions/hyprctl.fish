function hyprctl
    if test -d /run/user/1000/hypr
        set -lx HYPRLAND_INSTANCE_SIGNATURE (ls /run/user/1000/hypr/ 2>/dev/null | head -1)
    end
    command hyprctl $argv
end
