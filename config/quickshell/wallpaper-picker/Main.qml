import QtQuick
import QtQuick.Controls
import Quickshell
import "."

FloatingWindow {
    id: root
    visible: true
    title: "wallpaper-picker"
    color: "transparent"

    onVisibleChanged: {
        if (!visible) {
            Qt.quit()
        }
    }

    implicitWidth: Math.round(Screen.width * 0.94)
    implicitHeight: Math.round(Screen.height * 0.30)

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    WallpaperPicker {
        anchors.fill: parent
        focus: true
    }
}
