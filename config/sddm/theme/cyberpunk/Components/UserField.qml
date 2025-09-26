import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
  id: userField
  height: inputHeight
  width: inputWidth
  selectByMouse: true
  echoMode: TextInput.Normal
  selectionColor: config.overlay0
  renderType: Text.NativeRendering
  font {
    family: config.Font
    pointSize: config.FontSize
    bold: true
  }
  color: "#1a1b26"
  horizontalAlignment: Text.AlignHCenter
  placeholderText: "Username"
  text: userModel.lastUser
  background: Rectangle {
    id: userFieldBackground
    color: "#ffffff"
    opacity: 0.9
    radius: height / 2  // Pill shape
  }
  states: [
    State {
      name: "focused"
      when: userField.activeFocus
      PropertyChanges {
        userFieldBackground.color: config.surface1
      }
    },
    State {
      name: "hovered"
      when: userField.hovered
      PropertyChanges {
        userFieldBackground.color: config.surface1
      }
    }
  ]
  transitions: Transition {
    PropertyAnimation {
      properties: "color"
      duration: 300
    }
  }
}
