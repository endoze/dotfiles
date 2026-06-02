import QtQuick
import Quickshell

QtObject {
    readonly property string homeDir: Quickshell.env("HOME")

    property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string thumbDir: homeDir + "/.cache/wallpaper_picker/thumbs"

    property bool uiAnimationsEnabled: true
    property real uiAnimationScale: 1.0

    property string wallpaperTransitionType: "random"
    property real wallpaperTransitionDuration: 0.6
    property int wallpaperTransitionFps: 60

    property int closeDelayMs: 120
    property int scrollThrottleMs: 150

    // Runs after the wallpaper is applied, with the wallpaper path as $1.
    // Provided by wallpaper-picker.nix: updates the awww restore symlink and
    // runs wallust-apply (eww/shirase/walker recolor).
    property string extraReloadCommand: "wallpaper-picker-reload"
}
