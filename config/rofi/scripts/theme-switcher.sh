#!/usr/bin/env bash

# Theme Switcher Script
# Allows selecting a wallpaper from multiple directories,
# generates theme colors using wallust, and reloads all relevant applications.

# Directories to search for wallpapers
WALLPAPER_DIRS=(
    "$HOME/.config/hypr/wallpapers"
    "$HOME/Pictures/Wallpapers"
)

# Supported image extensions
EXTENSIONS=("jpg" "jpeg" "png" "webp" "gif" "bmp")

# Hyprpaper wallpaper symlink
CURRENT_WALLPAPER_LINK="$HOME/.config/hypr/current-wallpaper"

# Build find pattern for extensions
build_find_pattern() {
    local pattern=""
    for ext in "${EXTENSIONS[@]}"; do
        if [[ -n "$pattern" ]]; then
            pattern="$pattern -o"
        fi
        pattern="$pattern -iname *.$ext"
    done
    echo "$pattern"
}

# Find all wallpapers in configured directories
find_wallpapers() {
    local pattern
    pattern=$(build_find_pattern)

    for dir in "${WALLPAPER_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            # shellcheck disable=SC2086
            find "$dir" -type f \( $pattern \) 2>/dev/null
        fi
    done | sort -u
}

# Update wallpaper symlink
update_wallpaper_link() {
    local wallpaper="$1"
    ln -sf "$wallpaper" "$CURRENT_WALLPAPER_LINK"
}

# Reload hyprpaper with new wallpaper
reload_hyprpaper() {
    local wallpaper="$1"

    # Unload all wallpapers first
    hyprctl hyprpaper unload all &>/dev/null || true

    # Preload and set the new wallpaper
    hyprctl hyprpaper preload "$wallpaper" &>/dev/null || true
    hyprctl hyprpaper wallpaper ", $wallpaper" &>/dev/null || true
}

# Generate theme colors using wallust (skip terminal sequences)
generate_theme() {
    local wallpaper="$1"
    wallust run --skip-sequences "$wallpaper"
}

# Reload waybar
reload_waybar() {
    killall -SIGUSR2 .waybar-wrapped &>/dev/null || killall -SIGUSR2 waybar &>/dev/null || true
}

# Reload swaync - try CSS reload first, fallback to full restart if it times out
reload_swaync() {
    if ! timeout 2 swaync-client -rs &>/dev/null; then
        systemctl --user restart swaync &>/dev/null || true
    fi
}

# Format wallpapers for rofi with icon support
# Format: "display_name\0icon\x1f/path/to/image"
format_for_rofi() {
    while IFS= read -r wallpaper; do
        local basename
        basename=$(basename "$wallpaper")
        # Use printf to properly handle the special characters
        printf '%s\0icon\x1f%s\n' "$basename" "$wallpaper"
    done
}

# Main function
main() {
    local theme_file="$HOME/.config/rofi/themes/wallpaper-picker/style.rasi"

    # Get list of wallpapers
    local wallpapers
    wallpapers=$(find_wallpapers)

    if [[ -z "$wallpapers" ]]; then
        notify-send "Theme Switcher" "No wallpapers found in configured directories" &
        exit 1
    fi

    # Show rofi picker with image previews
    local selected_name
    selected_name=$(echo "$wallpapers" | format_for_rofi | rofi -dmenu -i -p "Wallpaper" -show-icons -theme "$theme_file" \
        -mesg "Select a wallpaper to apply") || true

    # Exit if nothing selected
    if [[ -z "$selected_name" ]]; then
        exit 0
    fi

    # Find the full path for the selected wallpaper
    local selected
    selected=$(echo "$wallpapers" | grep -F "/$selected_name" | head -1)

    if [[ -z "$selected" ]]; then
        notify-send "Theme Switcher" "Error: Could not find wallpaper path" &
        exit 1
    fi

    # Update wallpaper symlink (fast, do first)
    update_wallpaper_link "$selected"

    # Change wallpaper immediately for instant feedback
    reload_hyprpaper "$CURRENT_WALLPAPER_LINK" &

    # Run the rest in background so script exits quickly
    (
        # Generate theme colors (this is the slow part)
        wallust run --skip-sequences --quiet "$selected" 2>/dev/null

        # Reload apps in parallel
        reload_waybar &
        reload_swaync &
        wait
    ) &

    exit 0
}

main "$@"
