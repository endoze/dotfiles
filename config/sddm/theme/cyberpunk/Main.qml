import QtQuick 2.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects
import "Components"

Item {
  id: root
  height: Screen.height
  width: Screen.width
  Rectangle {
    id: background
    anchors.fill: parent
    height: parent.height
    width: parent.width
    z: 0
    color: config.base
  }
  Image {
    id: backgroundImage
    anchors.fill: parent
    height: parent.height
    width: parent.width
    fillMode: Image.PreserveAspectCrop
    visible: false
    source: config.Background
    asynchronous: false
    cache: true
    mipmap: true
    clip: true
  }

  // Apply blur effect
  FastBlur {
    id: blurredBackground
    anchors.fill: parent
    source: backgroundImage
    radius: 20
    transparentBorder: true
    visible: false
  }

  // Apply brightness and contrast adjustments to match hyprlock
  BrightnessContrast {
    anchors.fill: parent
    source: blurredBackground
    brightness: -0.2  // Hyprlock has 0.8 brightness (darker)
    contrast: 0.1     // Hyprlock has 1.3 contrast (higher)
    visible: config.CustomBackground == "true" ? true : false
    z: 1
  }

  Item {
    id: mainPanel
    z: 3
    anchors {
      fill: parent
      margins: 50
    }
    Clock {
      id: time
      visible: config.ClockEnabled == "true" ? true : false
    }
    LoginPanel {
      id: loginPanel
      anchors.fill: parent
    }
  }
}
